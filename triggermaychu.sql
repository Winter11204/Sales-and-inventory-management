use DBMSN3
GO
--Trigger cho bảng products
IF OBJECT_ID('tr_products','tr') is not null
DROP TRIGGER tr_products
GO
CREATE TRIGGER tr_products
ON [DBMSN3].[dbo].[products]
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @sc DECIMAL(9,2), @lp DECIMAL(9,2), @pid VARCHAR(10)
	SELECT @sc = standard_cost, @lp = list_price, @pid = product_id FROM inserted
	IF @sc <=0 or @lp <=0
	BEGIN
		PRINT N'Standard_cost và list_price phải lớn hơn 0'
	END

	IF EXISTS (
		SELECT 1
		FROM inserted
		WHERE @pid NOT LIKE 'PRD[0-9][0-9][0-9][0-9]' OR LEN(@pid) <> 7
	)
	BEGIN
		ROLLBACK TRAN;
		THROW 50001, N'Product_id không đúng định dạng cho phép.',1;
	END
END;

--Insert into PRODUCTS (PRODUCT_ID,PRODUCT_NAME,DESCRIPTION,STANDARD_COST,LIST_PRICE,CATEGORY_ID) 
--values ('PRD029a','Crucial CT525MX300SSD4','Series:MX300,Type:SSD,Capacity:525GB,Cache:N/A',121.92,150.99,5);

--Trigger cho bảng branches
IF OBJECT_ID ('tr_branches','tr') is not null
DROP TRIGGER tr_branches
GO
CREATE TRIGGER tr_branches
ON [DBMSN3].[dbo].[branches]
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @id varchar(10)
	SET @id = (SELECT BRANCH_ID FROM inserted)

	IF (@@ROWCOUNT = 0)
	BEGIN
		PRINT N'Bảng này không có dữ liệu'
		RETURN
	END

	IF EXISTS (
		SELECT 1
		FROM inserted
		WHERE branch_id LIKE 'AH%' AND LEN(branch_id) = 4
	)
	BEGIN
		PRINT N'Cập nhật thành công thông tin chi nhánh'
	END
	ELSE
	BEGIN
		ROLLBACK TRAN;
		THROW 50001,N'Lỗi nhập ID không bắt đầu bằng AH / ID không đúng định dạng',1;
	END
END;

--INSERT INTO BRANCHES (BRANCH_ID, BRANCH_NAME, PHONE, EMAIL, ADDRESS, CITY, STATE, ZIP_CODE) 
--VALUES ('AHMNY', 'American Hardware New York', '(206) 431-0981','newyorkstore@amerhard.com','185 Columbia Rd','New York','New York','02104');

--Trigger bảng customers
IF OBJECT_ID ('tr_customers','tr') is not null
DROP TRIGGER tr_customers
GO
CREATE TRIGGER tr_customers
ON [DBMSN3].[dbo].[customers]
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @bid VARCHAR(4)
	SELECT @bid = branch_id FROM [DBMSN3].[dbo].[branches]
	IF EXISTS (
		SELECT 1
		FROM inserted i
		WHERE SUBSTRING	(i.customer_id,1,4) NOT IN (SELECT branch_id FROM [DBMSN3].[dbo].[branches])
		   OR SUBSTRING	(i.customer_id,5,1) <> '-'
		   OR SUBSTRING (i.customer_id,6,5) <> 'CusID'
		   OR SUBSTRING	(i.customer_id,11,1) <> '-'
	)
	BEGIN
		ROLLBACK TRAN;
		THROW 50002, N'Customer_id không đúng định dạng cho phép, xin hãy nhập mã đúng theo định dạng: ID chi nhánh-CusID-Tên viết tắt của tên khách hàng',1;
	END
END;

--INSERT INTO [DBMSN3].[dbo].[CUSTOMERS] (CUSTOMER_ID,NAME,ADDRESS,WEBSITE) 
--VALUES ('AHTK-CusOD-SRE','Sempra Energy','633 S Hawley Rd, Milwaukee, WI','http://www.sempra.com');


--Trigger bảng contacts
IF OBJECT_ID ('tr_contacts','tr') is not nulL
DROP TRIGGER tr_contacts
GO
CREATE TRIGGER tr_contacts
ON [DBMSN3].[dbo].[contacts]
AFTER INSERT, UPDATE
AS
BEGIN
	IF EXISTS (
		SELECT 1
		FROM inserted i
		WHERE LEFT(i.contact_id,2) <> SUBSTRING(i.customer_id,3,2)
		   OR RIGHT(i.contact_id,3) NOT LIKE '[0-9][0-9][0-9]'
	)
	BEGIN
		ROLLBACK TRAN;
		THROW 50002, N'Contact_id không đúng định dạng cho phép, xin hãy nhập mã đúng theo định dạng: 2 kí tự cuôi của mã chi nhánh đơn hàng được đặt + số thứ tự của đơn hàng',1;
	END

	IF EXISTS (
		SELECT 1
		FROM inserted i
		WHERE i.phone NOT LIKE '+1 [0-9][0-9][0-9] [0-9][0-9][0-9] [0-9][0-9][0-9][0-9]'
		   OR LEN(i.phone) <> 15
	)
	BEGIN
		ROLLBACK TRAN;
		THROW 50001, N'Định dạng số điện thoại không đúng theo chuẩn, xin hãy nhập lại',1;
	END
END;

--INSERT INTO CONTACTS (CONTACT_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE, CUSTOMER_ID) 
--VALUES ('FA069', 'Richard', 'Miller', 'richard.miller@raytheon.com', '+1 4185 669 2203', 'AHFL-CusID-RTX');

--Trigger cho bảng Employees
IF OBJECT_ID ('tr_employees','tr') is not null
DROP TRIGGER tr_employees
GO
CREATE TRIGGER tr_employees
ON [DBMSN3].[dbo].[employees]
AFTER INSERT, UPDATE
AS 
BEGIN
	DECLARE @eidcheck varchar(10)
	SET @eidcheck = (SELECT branch_id FROM inserted)
	SET @eidcheck = left(@eidcheck,5)

	IF EXISTS (
		SELECT 1
		FROM inserted
		WHERE SUBSTRING(employee_id,1,4) <> branch_id 
		   OR SUBSTRING(employee_id,5,2) NOT LIKE '[0-9][0-9]'
		   OR LEN(employee_id) <> 6
	)
	BEGIN
		ROLLBACK TRAN;
		THROW 50001, N'Employee_id bị sai định dạng',1;
	END
END;

--INSERT INTO EMPLOYEES (EMPLOYEE_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE, HIRE_DATE, JOB_TITLE, BRANCH_ID)
--VALUES ('AHNA21', 'Amelia', 'Myers', 'amelia.myers@example.com', '650.121.8009', '2016-10-17', 'Vice Branch Manager', 'AHNJ');

--Trigger cho bảng Inventories
IF OBJECT_ID('tr_inventories','tr') is not null
DROP TRIGGER tr_inventories
GO
CREATE TRIGGER tr_inventories
ON [DBMSN3].[dbo].[inventories]
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @qt INT
	SELECT @qt = quantity FROM inserted
	IF @qt < 0
	BEGIN
		ROLLBACK TRAN;
		THROW 50001,N'Số lượng sản phẩm nhập sai quy định',1;
	END
END;

--INSERT INTO INVENTORIES (product_id, branch_id, quantity) 
--VALUES ('PRD0203', 'AHMA', -1);

--Trigger cho bảng orders
IF OBJECT_ID('tr_orders','tr') is not null
DROP TRIGGER tr_orders
GO
CREATE TRIGGER tr_orders
ON [DBMSN3].[dbo].[orders]
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @sysdate DATE = GETDATE()
	IF EXISTS (
		SELECT 1
		FROM inserted i
		WHERE LEN(i.order_id) <> 13
		  OR SUBSTRING(i.order_id,1,3) <> SUBSTRING(i.salesman_id,3,2) + '-'
		  OR SUBSTRING(i.order_id,4,4) <> CAST(YEAR(i.order_date) AS VARCHAR(4))
		  OR SUBSTRING(i.order_id,8,1) <> '-'
		  OR SUBSTRING (i.order_id,9,5) NOT LIKE '[0-9][0-9][0-9][0-9][0-9]'
	)
	BEGIN
		ROLLBACK TRAN;
		THROW 50001, N'Order_id không đúng định dạng cho phép, xin hãy nhập mã đúng theo định dạng: 2 kí tự cuôi của mã chi nhánh đơn hàng được đặt-năm đơn hàng được tạo-thứ tự đơn hàng',1;
	END

	DECLARE @st VARCHAR(20)
	SELECT @st = status
	FROM inserted
	IF @st NOT IN ('Shipped','Canceled','Pending')
	BEGIN
		ROLLBACK TRAN;
		THROW 50002, N'Trạng thái đơn hàng (status) không đúng định dạnh cho phép',1;
	END

	IF EXISTS (
		SELECT 1
		FROM inserted i
		JOIN employees e ON i.salesman_id = e.employee_id
		WHERE i.order_date < e.hire_date
	)
	BEGIN
		ROLLBACK TRAN;
		THROW 50004,N'Ngày đặt đơn phải sau ngày nhân viên được thuê',1;
	END
END;

--INSERT INTO ORDERS (ORDER_ID,CUSTOMER_ID,STATUS,SALESMAN_ID,ORDER_DATE) 
--VALUES ('CA-2011-00001','AHCA-CusID-ABBV','Shipped','AHCA06','2011-09-14');

--Trigger bảng order_items
IF OBJECT_ID ('tr_insert_order_items','tr') is not null
DROP TRIGGER tr_insert_order_items
GO
CREATE TRIGGER tr_insert_order_items
ON [DBMSN3].[dbo].[order_items]
AFTER INSERT
AS
BEGIN
	IF EXISTS ( SELECT 1 FROM inserted WHERE quantity <= 0 OR unit_price <= 0 )
	BEGIN
		ROLLBACK TRAN;
		THROW 50003,N'Số lượng sản phẩm phải và giá của sản phẩm phải lớn hơn 0',1;
	END
	IF EXISTS (
		SELECT oi.order_id
		FROM order_items AS oi
		GROUP BY oi.order_id
		HAVING COUNT(*) <> MAX(oi.item_id)
	)
	BEGIN
		ROLLBACK TRANSACTION;
		THROW 50001, N'Item_ID không theo thứ tự liên tục.', 1;
	END
	DECLARE @oid VARCHAR(255)
	DECLARE @item_id INT
	DECLARE @new FLOAT
	DECLARE @pid VARCHAR(255)
	SELECT @oid = order_id,@item_id= item_id, @new=quantity, @pid= product_id FROM inserted
	SET @oid = left(@oid,2)
	SET @oid = 'AH' + @oid
	DECLARE @tonkho INT
	SELECT @tonkho = quantity FROM [DBMSN3].[dbo].[inventories] WHERE product_id = @pid and branch_id = @oid
	IF @tonkho is null 
	BEGIN
		ROLLBACK TRAN;
		THROW 50002,N'Sản phẩm hiện đang không có trong kho hàng, hãy kiểm tra lại.',1;
	END
	IF @new >@tonkho
	BEGIN
		ROLLBACK TRAN;
		THROW 50003,N'Số lượng sản phẩm vượt quá số lượng trong hàng tồn kho, vui lòng kiểm tra lại.',1
	END
	-- @oidd cũng là order_id, những đơn bị huỷ thì không cần cập nhật số lượng trong kho
	DECLARE @oidd VARCHAR(255)
	SET @oidd= (SELECT order_id FROM  inserted)
	DECLARE @status VARCHAR(255)
	SET @status=(SELECT [status] FROM orders WHERE order_id=@oidd)
	if @status<>'Canceled'
	BEGIN
		UPDATE [DBMSN3].[dbo].[inventories] SET quantity=@tonkho-@new WHERE branch_id=@oid and product_id=@pid
	END
END;
GO

--Insert into [DBMSN3].[dbo].[order_items] (ORDER_ID,ITEM_ID,PRODUCT_ID,QUANTITY,UNIT_PRICE) 
--values ('CA-2017-00008',12,'PRD0003',2,469.99);

IF OBJECT_ID ('tr_update_order_items','tr') is not null
DROP TRIGGER tr_update_order_items
GO
CREATE TRIGGER tr_update_order_items
ON [DBMSN3].[dbo].[order_items]
INSTEAD OF update
AS
BEGIN
	IF EXISTS (
		SELECT 1
		FROM inserted
		WHERE quantity <= 0 OR unit_price <= 0
	)
	BEGIN
		ROLLBACK TRAN;
		THROW 50003,N'Số lượng sản phẩm phải và giá của sản phẩm phải lớn hơn 0',1;
	END

	IF update(product_id) or update(item_id) or update(order_id)
	BEGIN
		ROLLBACK TRAN;
		THROW 50001, N'Không được phép cập nhật dữ liệu nào khác ngoài quantity,unit_price',1;
	END
	ELSE 
	BEGIN
		DECLARE @oid VARCHAR(255), @item_id INT, @new FLOAT, @pid VARCHAR(255), @price FLOAT
		SELECT @oid = order_id,@item_id= item_id, @new=quantity, @pid= product_id, @price=unit_price FROM inserted
		DECLARE @old FLOAT
		SET @old = (SELECT quantity FROM [DBMSN3].[dbo].[order_items] a WHERE a.order_id =@oid and a.item_id=@item_id )
		SET @oid = left(@oid,2)
		SET @oid = 'AH' + @oid
		DECLARE @tonkho INT
		SELECT @tonkho = quantity FROM [DBMSN3].[dbo].[inventories] WHERE product_id = @pid and branch_id = @oid
		IF @tonkho is null
		BEGIN
			ROLLBACK TRAN;
			THROW 50002,N'Sản phẩm hiện đang không có trong kho hàng, hãy kiểm tra lại.',1;
		END
		IF @new >@tonkho+@old
		BEGIN
			ROLLBACK TRAN;
			THROW 50003,N'Số lượng sản phẩm vượt quá số lượng trong hàng tồn kho, vui lòng kiểm tra lại.',1
		END
		DECLARE @oidd VARCHAR(255)
		SET @oidd= (SELECT order_id FROM  inserted)
		--cập nhật trong bảng order_items
		UPDATE [DBMSN3].[dbo].[order_items] set quantity=@new, unit_price=@price WHERE order_id= @oidd and item_id=@item_id
		DECLARE @status VARCHAR(255)
		SET @status=(SELECT [status] FROM orders WHERE order_id=@oidd)
		--những đơn bị huỷ thì không cần cập nhật số lượng trong kho
		IF @status<>'Canceled'
		BEGIN
			UPDATE [DBMSN3].[dbo].[inventories] SET quantity=@tonkho-@new+@old WHERE branch_id=@oid and product_id=@pid
		END
	END
END;
GO

--update order_items set quantity = 40 where order_id='CA-2013-00001' and item_id=3
