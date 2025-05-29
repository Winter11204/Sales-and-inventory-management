--Create database
USE [master]
IF EXISTS (SELECT name FROM master.sys.databases WHERE name = 'DBMSN3')
DROP DATABASE [DBMSN3]
GO
CREATE DATABASE DBMSN3;
GO
USE DBMSN3;
GO
--Create table:
--Table warehouses
CREATE TABLE branches
(
    branch_id VARCHAR(10) PRIMARY KEY,
    branch_name VARCHAR(255) NOT NULL,
	phone VARCHAR(25),
	email VARCHAR(255),
	address VARCHAR(255),
	city VARCHAR(255),
    state VARCHAR(255),
	zip_code VARCHAR(5)
);

--Table employees
CREATE TABLE employees
(
    employee_id VARCHAR(10) PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    hire_date DATE NOT NULL,
    job_title VARCHAR(255) NOT NULL,
	branch_id VARCHAR(10),
    FOREIGN KEY(branch_id) REFERENCES branches(branch_id) ON DELETE CASCADE
);

--Table product_categories
CREATE TABLE product_categories
(
    category_id INT PRIMARY KEY,
    category_name VARCHAR(255) NOT NULL
);

--Table products
CREATE TABLE products
(
    product_id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    description VARCHAR(2000),
    standard_cost DECIMAL(9,2),
    list_price DECIMAL(9,2),
    category_id INT NOT NULL,
    FOREIGN KEY(category_id) REFERENCES product_categories(category_id) ON DELETE CASCADE
);

CREATE TABLE customers
(
    customer_id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(255),
	website VARCHAR(255)
);

--Table contacts
CREATE TABLE contacts
(
    contact_id VARCHAR(10) PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    customer_id VARCHAR(20),
    FOREIGN KEY(customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);

--Table orders
CREATE TABLE orders
(
    order_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL,
    salesman_id VARCHAR(10),
    order_date DATE NOT NULL,
    FOREIGN KEY(customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    FOREIGN KEY(salesman_id) REFERENCES employees(employee_id) ON DELETE SET NULL
);

--Table order_items
CREATE TABLE order_items
(
    order_id VARCHAR(20) NOT NULL,
    item_id INT NOT NULL,
    product_id VARCHAR(10) NOT NULL,
    quantity DECIMAL(8,2) NOT NULL,
    unit_price DECIMAL(8,2) NOT NULL,
    PRIMARY KEY(order_id, item_id),
    FOREIGN KEY(product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY(order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);

--Table inventories
CREATE TABLE inventories
(
    product_id VARCHAR(10) NOT NULL,
    branch_id VARCHAR(10) NOT NULL,
    quantity INT NOT NULL,
    PRIMARY KEY(product_id, branch_id),
    FOREIGN KEY(product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY(branch_id) REFERENCES branches(branch_id) ON DELETE CASCADE
);
