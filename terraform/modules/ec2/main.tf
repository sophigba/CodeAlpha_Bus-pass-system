# terraform/modules/ec2/main.tf

resource "aws_launch_template" "buspass_lt" {
  name_prefix   = "buspass-"
  image_id      = "ami-0c02fb55956c7d316" # Amazon Linux 2, us-east-1
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.ec2_sg_id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3 python3-pip mysql
    pip3 install flask flask-cors pymysql

    # Create app directory
    mkdir -p /var/www/buspass
    cd /var/www/buspass

    # Write app.py inline
    cat > app.py << 'PYEOF'
from flask import Flask, request, jsonify
from flask_cors import CORS
import pymysql
import os
import hashlib

app = Flask(__name__)
CORS(app)  # Allow frontend (CloudFront) to call this API

def get_db():
    return pymysql.connect(
        host=os.environ.get('DB_HOST', 'localhost'),
        user=os.environ.get('DB_USER', 'admin'),
        password=os.environ.get('DB_PASS', ''),
        database='buspassdb',
        cursorclass=pymysql.cursors.DictCursor
    )

@app.route('/health')
def health():
    return jsonify({"status": "healthy"}), 200

@app.route('/register', methods=['POST'])
def register():
    data = request.json
    db = get_db()
    cursor = db.cursor()
    # NOTE: Raw string query — intentionally vulnerable for Phase 2
    cursor.execute(
        f"INSERT INTO users (full_name, email, password) "
        f"VALUES ('{data['name']}', '{data['email']}', '{data['password']}')"
    )
    db.commit()
    user_id = cursor.lastrowid
    db.close()
    return jsonify({"message": "Registered", "user": {"id": user_id, "name": data['name'], "email": data['email']}}), 201

@app.route('/login', methods=['POST'])
def login():
    data = request.json
    db = get_db()
    cursor = db.cursor()
    # NOTE: Raw string query — intentionally vulnerable for Phase 2
    cursor.execute(
        f"SELECT * FROM users WHERE email='{data['email']}' AND password='{data['password']}'"
    )
    user = cursor.fetchone()
    db.close()
    if user:
        return jsonify({"message": "Login successful", "user": {"id": user['id'], "name": user['full_name'], "email": user['email']}}), 200
    return jsonify({"message": "Invalid credentials"}), 401

@app.route('/book', methods=['POST'])
def book():
    data = request.json
    db = get_db()
    cursor = db.cursor()
    cursor.execute(
        f"INSERT INTO bus_passes (user_id, route, pass_type, start_date, expiry_date, status) "
        f"VALUES ('{data['user_id']}', '{data['route']}', '{data['pass_type']}', "
        f"'{data['start_date']}', '{data['expiry_date']}', 'active')"
    )
    pass_id = cursor.lastrowid
    cursor.execute(
        f"INSERT INTO bookings (user_id, pass_id, amount, payment_status) "
        f"VALUES ('{data['user_id']}', '{pass_id}', '{data['amount']}', 'paid')"
    )
    db.commit()
    db.close()
    return jsonify({"message": "Pass booked", "pass_id": pass_id}), 201

@app.route('/passes/<user_id>', methods=['GET'])
def get_passes(user_id):
    db = get_db()
    cursor = db.cursor()
    cursor.execute(f"SELECT * FROM bus_passes WHERE user_id='{user_id}'")
    passes = cursor.fetchall()
    db.close()
    return jsonify({"passes": passes}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
PYEOF

    # Set DB environment variables (replace with your actual RDS values)
    export DB_HOST="${var.db_host}"
    export DB_USER="${var.db_user}"
    export DB_PASS="${var.db_pass}"

    # Run the Flask app
    python3 app.py &
  EOF
  )
}

resource "aws_autoscaling_group" "buspass_asg" {
  name                = "buspass-asg"
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2
  vpc_zone_identifier = [var.public_subnet_a_id, var.public_subnet_b_id]

  launch_template {
    id      = aws_launch_template.buspass_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "BusPass-EC2"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  autoscaling_group_name = aws_autoscaling_group.buspass_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}