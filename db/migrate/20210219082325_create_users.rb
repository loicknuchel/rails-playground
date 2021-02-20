class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :password
      t.integer :role

      t.timestamps
    end
    User.create(name: 'Admin', email: 'admin@mail.com', password: 'admin', role: 'admin')
    User.create(name: 'Author', email: 'author@mail.com', password: 'author', role: 'author')
    User.create(name: 'Guest', email: 'guest@mail.com', password: 'guest', role: 'guest')
  end
end
