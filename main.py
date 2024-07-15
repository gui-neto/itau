from flask import Flask, request, jsonify

app = Flask(__name__)

# Dados em memória
users = []
accounts = []
user_id_counter = 1
account_id_counter = 1

# Rota para criar um novo usuário
@app.route('/users', methods=['POST'])
def create_user():
    global user_id_counter
    data = request.get_json()
    name = data.get('name')
    email = data.get('email')
    password = data.get('password')
    address = data.get('address')
    phone = data.get('phone')

    if not name or not email or not password:
        return jsonify({'error': 'Name, email, and password are required'}), 400

    user = {
        'id': user_id_counter,
        'name': name,
        'email': email,
        'password': password,
        'address': address,
        'phone': phone,
        'created_at': 'now',
        'updated_at': 'now'
    }
    users.append(user)
    user_id_counter += 1

    return jsonify({'message': 'User created successfully', 'user': user}), 201

# Rota para obter informações de um usuário
@app.route('/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    user = next((user for user in users if user['id'] == user_id), None)
    if user is None:
        return jsonify({'error': 'User not found'}), 404
    return jsonify(user), 200

# Rota para atualizar um usuário
@app.route('/users/<int:user_id>', methods=['PUT'])
def update_user(user_id):
    user = next((user for user in users if user['id'] == user_id), None)
    if user is None:
        return jsonify({'error': 'User not found'}), 404

    data = request.get_json()
    user['name'] = data.get('name', user['name'])
    user['email'] = data.get('email', user['email'])
    user['password'] = data.get('password', user['password'])
    user['address'] = data.get('address', user['address'])
    user['phone'] = data.get('phone', user['phone'])
    user['updated_at'] = 'now'

    return jsonify({'message': 'User updated successfully', 'user': user}), 200

# Rota para deletar um usuário
@app.route('/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    global users
    users = [user for user in users if user['id'] != user_id]
    return jsonify({'message': 'User deleted successfully'}), 200

# Rota para criar uma nova conta bancária
@app.route('/accounts', methods=['POST'])
def create_account():
    global account_id_counter
    data = request.get_json()
    user_id = data.get('user_id')
    account_type = data.get('account_type')
    balance = data.get('balance', 0.0)

    if not user_id or not account_type:
        return jsonify({'error': 'User ID and account type are required'}), 400

    account = {
        'id': account_id_counter,
        'user_id': user_id,
        'account_type': account_type,
        'balance': balance,
        'created_at': 'now',
        'updated_at': 'now'
    }
    accounts.append(account)
    account_id_counter += 1

    return jsonify({'message': 'Account created successfully', 'account': account}), 201

# Rota para obter informações de uma conta
@app.route('/accounts/<int:account_id>', methods=['GET'])
def get_account(account_id):
    account = next((account for account in accounts if account['id'] == account_id), None)
    if account is None:
        return jsonify({'error': 'Account not found'}), 404
    return jsonify(account), 200

# Rota para realizar um depósito
@app.route('/accounts/<int:account_id>/deposit', methods=['POST'])
def deposit(account_id):
    account = next((account for account in accounts if account['id'] == account_id), None)
    if account is None:
        return jsonify({'error': 'Account not found'}), 404

    data = request.get_json()
    amount = data.get('amount')

    try:
        amount = float(amount)
    except (TypeError, ValueError):
        return jsonify({'error': 'Invalid amount'}), 400

    if amount <= 0:
        return jsonify({'error': 'Invalid amount'}), 400

    account['balance'] += amount
    account['updated_at'] = 'now'

    return jsonify({'message': 'Deposit successful', 'account': account}), 200

# Rota para realizar um saque
@app.route('/accounts/<int:account_id>/withdraw', methods=['POST'])
def withdraw(account_id):
    account = next((account for account in accounts if account['id'] == account_id), None)
    if account is None:
        return jsonify({'error': 'Account not found'}), 404

    data = request.get_json()
    amount = data.get('amount')

    try:
        amount = float(amount)
    except (TypeError, ValueError):
        return jsonify({'error': 'Invalid amount'}), 400

    if amount <= 0 or amount > account['balance']:
        return jsonify({'error': 'Invalid amount'}), 400

    account['balance'] -= amount
    account['updated_at'] = 'now'

    return jsonify({'message': 'Withdrawal successful', 'account': account}), 200

# Rota para realizar uma transferência
@app.route('/accounts/transfer', methods=['POST'])
def transfer():
    data = request.get_json()
    from_account_id = data.get('from_account_id')
    to_account_id = data.get('to_account_id')
    amount = data.get('amount')

    try:
        amount = float(amount)
    except (TypeError, ValueError):
        return jsonify({'error': 'Invalid amount'}), 400

    if not from_account_id or not to_account_id or amount <= 0:
        return jsonify({'error': 'Invalid input'}), 400

    from_account = next((account for account in accounts if account['id'] == from_account_id), None)
    to_account = next((account for account in accounts if account['id'] == to_account_id), None)

    if from_account is None or to_account is None:
        return jsonify({'error': 'One or both accounts not found'}), 404
    if from_account['balance'] < amount:
        return jsonify({'error': 'Insufficient funds'}), 400

    from_account['balance'] -= amount
    to_account['balance'] += amount
    from_account['updated_at'] = 'now'
    to_account['updated_at'] = 'now'

    return jsonify({'message': 'Transfer successful', 'from_account': from_account, 'to_account': to_account}), 200

if __name__ == '__main__':
    app.run(debug=True)
