-- Create Products table
CREATE TABLE Products (
    product_id NUMBER PRIMARY KEY,
    product_name VARCHAR2(100) NOT NULL,
    description VARCHAR2(500),
    unit_price NUMBER(10,2) NOT NULL,
    quantity_in_stock NUMBER DEFAULT 0
);

-- Create Suppliers table
CREATE TABLE Suppliers (
    supplier_id NUMBER PRIMARY KEY,
    supplier_name VARCHAR2(100) NOT NULL,
    contact_person VARCHAR2(100),
    phone_number VARCHAR2(20)
);

-- Create Inventory_Transactions table
CREATE TABLE Inventory_Transactions (
    transaction_id NUMBER PRIMARY KEY,
    product_id NUMBER,
    transaction_type VARCHAR2(10) CHECK (transaction_type IN ('IN', 'OUT')),
    quantity NUMBER,
    transaction_date DATE DEFAULT SYSDATE,
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- Procedure to add a new product
CREATE OR REPLACE PROCEDURE add_product(
    p_product_name IN VARCHAR2,
    p_description IN VARCHAR2,
    p_unit_price IN NUMBER,
    p_quantity IN NUMBER
)
IS
BEGIN
    INSERT INTO Products (product_id, product_name, description, unit_price, quantity_in_stock)
    VALUES (product_seq.NEXTVAL, p_product_name, p_description, p_unit_price, p_quantity);
    COMMIT;
END;
/

-- Procedure to update product quantity
CREATE OR REPLACE PROCEDURE update_product_quantity(
    p_product_id IN NUMBER,
    p_quantity_change IN NUMBER,
    p_transaction_type IN VARCHAR2
)
IS
BEGIN
    UPDATE Products
    SET quantity_in_stock = quantity_in_stock + 
        CASE WHEN p_transaction_type = 'IN' THEN p_quantity_change
             ELSE -p_quantity_change
        END
    WHERE product_id = p_product_id;
    
    INSERT INTO Inventory_Transactions (transaction_id, product_id, transaction_type, quantity)
    VALUES (transaction_seq.NEXTVAL, p_product_id, p_transaction_type, p_quantity_change);
    
    COMMIT;
END;
/

CREATE OR REPLACE TRIGGER trg_update_product_quantity
AFTER INSERT ON Inventory_Transactions
FOR EACH ROW
BEGIN
    UPDATE Products
    SET quantity_in_stock = quantity_in_stock + 
        CASE WHEN :NEW.transaction_type = 'IN' THEN :NEW.quantity
             ELSE -:NEW.quantity
        END
    WHERE product_id = :NEW.product_id;
END;
/
CREATE OR REPLACE TRIGGER trg_update_product_quantity
AFTER INSERT ON Inventory_Transactions
FOR EACH ROW
BEGIN
    UPDATE Products
    SET quantity_in_stock = quantity_in_stock + 
        CASE WHEN :NEW.transaction_type = 'IN' THEN :NEW.quantity
             ELSE -:NEW.quantity
        END
    WHERE product_id = :NEW.product_id;
END;
/

CREATE OR REPLACE PACKAGE inventory_reports AS
    -- Function to get current stock value
    FUNCTION get_total_stock_value RETURN NUMBER;
    
    -- Procedure to generate low stock report
    PROCEDURE generate_low_stock_report(p_threshold IN NUMBER);
END inventory_reports;
/

CREATE OR REPLACE PACKAGE BODY inventory_reports AS
    FUNCTION get_total_stock_value RETURN NUMBER IS
        v_total_value NUMBER;
    BEGIN
        SELECT SUM(quantity_in_stock * unit_price)
        INTO v_total_value
        FROM Products;
        
        RETURN v_total_value;
    END get_total_stock_value;
    
    PROCEDURE generate_low_stock_report(p_threshold IN NUMBER) IS
    BEGIN
        FOR r IN (SELECT product_name, quantity_in_stock
                  FROM Products
                  WHERE quantity_in_stock < p_threshold
                  ORDER BY quantity_in_stock)
        LOOP
            DBMS_OUTPUT.PUT_LINE(r.product_name || ': ' || r.quantity_in_stock);
        END LOOP;
    END generate_low_stock_report;
END inventory_reports;
/