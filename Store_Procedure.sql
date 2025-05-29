USE DBMSN3
GO

--Tính giá trị đơn hàng có mã là @order_id, nếu không ghi order_id thì sẽ in ra giá trị của tất cả đơn
IF OBJECT_ID('sp_bill','p') is not null
DROP PROCEDURE sp_bill
go
CREATE PROCEDURE sp_bill (@Order_id VARCHAR(255) = NULL)
AS
BEGIN
	SET NOCOUNT ON
	IF @Order_id is not null and NOT EXISTS (SELECT 1 FROM orders WHERE order_id = @Order_id)
	BEGIN
		RAISERROR (N'Order ID %s không tồn tại.',16,1,@Order_id);
		RETURN;
	END

	IF @Order_id IS NULL
	BEGIN
		SELECT oi.order_id, sum(oi.quantity * oi.unit_price) as N'Giá trị của đơn hàng'
		FROM order_items oi
		GROUP BY oi.order_id
		ORDER BY oi.order_id;
	END
	ELSE
	BEGIN
		SELECT oi.order_id, sum(oi.quantity * oi.unit_price) as N'Giá trị của đơn hàng'
		FROM order_items oi
		WHERE oi.order_id = @Order_id
		GROUP BY oi.order_id
	END
END;
GO

--EXEC sp_bill @Order_id = 'CA-2015-00001';
--EXEC sp_bill;

--Xem đơn hàng mà khách hàng có mã khách hàng là @customer_id đã mua
IF OBJECT_ID ('sp_bill_of_customer','p') is not null
DROP PROCEDURE sp_bill_of_customer
GO
CREATE PROCEDURE sp_bill_of_customer (@Customer_id VARCHAR(255))
AS
BEGIN
	SET NOCOUNT ON
	IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_id = @Customer_id)
	BEGIN
		RAISERROR (N'Khách hàng có mã %s không tồn tại hoặc bạn chưa nhập mã khách hàng',16,1,@Customer_id);
		RETURN;
	END
	ELSE
	BEGIN
		SELECT o.order_id,o.customer_id, o.status, o.salesman_id, o.order_date, SUM(oi.quantity * oi.unit_price) as N'Giá trị của đơn hàng'
		FROM Orders o
		INNER JOIN order_items oi on o.order_id = oi.order_id
		WHERE o.customer_id = @Customer_id
		GROUP BY o.order_id,o.customer_id, o.status, o.salesman_id, o.order_date
		ORDER BY order_date ASC, order_id
	END
END;
GO

--EXEC sp_bill_of_customer 'AHCA-CusID-CYH'

--Tính tổng tiền mà khách hàng có mã @customer_id đã chi
IF OBJECT_ID('sp_total_of_customer','p')  is not null
DROP PROCEDURE sp_total_of_customer
GO
CREATE PROCEDURE sp_total_of_customer (@customer_id VARCHAR(255))
AS
BEGIN
	SET NOCOUNT ON
	IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_id = @Customer_id)
	BEGIN
		RAISERROR (N'Khách hàng có mã %s không tồn tại hoặc bạn chưa nhập mã khách hàng, xin hãy nhập lại',16,1,@Customer_id);
		RETURN;
	END
	ELSE
	BEGIN
		SELECT o.customer_id, SUM(oi.quantity * oi.unit_price) AS N'Tổng số tiền mà khách hàng đã chi'
		FROM orders o
		INNER JOIN order_items oi ON o.order_id = oi.order_id
		WHERE o.customer_id = @customer_id AND o.status = 'Shipped'
		GROUP BY o.customer_id
	END
END;
GO

EXEC sp_total_of_customer 'AHCA-CusID-CYH'

--Thống kê doanh thu của nhân viên có mã là @employee_id, nếu không điền mã thì in ra tất cả
IF OBJECT_ID('sp_revenue_of_employee','P') IS NOT NULL
DROP PROCEDURE sp_revenue_of_employee
GO
CREATE PROCEDURE sp_revenue_of_employee (@employee_id VARCHAR(255) = NULL)
AS
BEGIN
	SET NOCOUNT ON
	IF @employee_id IS NOT NULL AND NOT EXISTS (
		SELECT 1
		FROM employees
		WHERE employee_id = @employee_id
	)
	BEGIN
		RAISERROR (N'Nhân viên có mã %s không tồn tại hoặc bạn đã nhập sai mã nhân viên, xin hãy nhập lại',16,1,@employee_id);
	END
	
	IF @employee_id IS NULL
	BEGIN
		SELECT o.salesman_id, e.first_name, e.last_name, e.email, e.phone, e.hire_date, e.job_title, sum(oi.quantity * oi.unit_price) as N'Tổng doanh thu của nhân viên'
		FROM orders o
		INNER JOIN employees e ON o.salesman_id = e.employee_id
		INNER JOIN order_items oi ON o.order_id = oi.order_id
		WHERE o.status = 'Shipped'
		GROUP BY o.salesman_id, e.first_name, e.last_name, e.email, e.phone, e.hire_date, e.job_title
	END
	ELSE
	BEGIN
	SELECT o.salesman_id, e.first_name, e.last_name, e.email, e.phone, e.hire_date, e.job_title, sum(oi.quantity * oi.unit_price) as N'Tổng doanh thu của nhân viên'
	FROM orders o
	INNER JOIN employees e ON o.salesman_id = e.employee_id
	INNER JOIN order_items oi ON o.order_id = oi.order_id
	WHERE o.salesman_id = @employee_id AND o.status = 'Shipped'
	GROUP BY o.salesman_id, e.first_name, e.last_name, e.email, e.phone, e.hire_date, e.job_title;
	END
END;
GO

EXEC sp_revenue_of_employee
EXEC sp_revenue_of_employee 'AHCA07'

--Thống kê doanh thu của từng chi nhánh, nếu không nhập mã chi nhánh thì in ra doanh thu của tất cả chi nhánh
IF OBJECT_ID ('sp_revenue_of_branch','P') IS NOT NULL
DROP PROCEDURE sp_revenue_of_branch
GO
CREATE PROCEDURE sp_revenue_of_branch (@branch_id VARCHAR(10) = NULL)
AS
BEGIN
	SET NOCOUNT ON
	IF @branch_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM branches WHERE branch_id = @branch_id)
	BEGIN
		RAISERROR (N'Chi nhánh có mã %s không tồn tại hoặc bạn đã nhập sai mã chi nhánh, xin hãy nhập lại',16,1,@branch_id)
		RETURN;
	END

	IF @branch_id IS NULL
	BEGIN
		SELECT e.branch_id, sum(oi.quantity * oi.unit_price) as N'Tổng doanh thu của chi nhánh'
		FROM orders o
		INNER JOIN employees e ON o.salesman_id = e.employee_id
		INNER JOIN order_items oi ON o.order_id = oi.order_id
		WHERE o.status = 'Shipped'
		GROUP BY e.branch_id;
	END
	ELSE
	BEGIN
		SELECT e.branch_id, sum(oi.quantity * oi.unit_price) as N'Tổng doanh thu của chi nhánh'
		FROM orders o
		INNER JOIN employees e ON o.salesman_id = e.employee_id
		INNER JOIN order_items oi ON o.order_id = oi.order_id
		WHERE e.branch_id = @branch_id AND o.status = 'Shipped'
		GROUP BY e.branch_id;
	END
END;
GO

EXEC sp_revenue_of_branch
EXEC sp_revenue_of_branch 'AHCA'

--In ra tổng doanh thu trên toàn chi nhánh trong một khoảng thời gian, nếu không nhập gì thì in ra tổng doanh thu từ trước đến giờ
IF OBJECT_ID ('sp_revenue','p') IS NOT NULL
DROP PROCEDURE sp_revenue
GO

CREATE PROCEDURE sp_revenue (@startdate DATE = NULL, @enddate DATE = NULL)
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @sysdate DATETIME
	SET @sysdate = GETDATE()
	IF @startdate >= @sysdate or @enddate >= @sysdate or @enddate < @startdate
	BEGIN
		RAISERROR(N'Khoảng thời gian nhập vào không hợp lệ, xin hãy nhập lại.',16,1);
		RETURN;
	END
	IF @startdate IS NULL AND @enddate IS NULL
	BEGIN
		SELECT SUM(oi.quantity * oi.unit_price) as N'Tổng doanh thu'
		FROM orders o
		INNER JOIN order_items oi on oi.order_id = o.order_id
		WHERE o.order_date < @sysdate  and o.status = 'Shipped';
	END
	ELSE
	BEGIN
		SELECT SUM(oi.quantity * oi.unit_price) as N'Tổng doanh thu'
		FROM orders o
		INNER JOIN order_items oi on oi.order_id = o.order_id
		WHERE (o.order_date BETWEEN @startdate AND @enddate) and o.status = 'Shipped';
	END
END;
GO

EXEC sp_revenue
EXEC sp_revenue '2015-10-10','2017-10-10'

--In ra số nhân viên của chi nhánh, nếu không nhập gì thì in ra toàn bộ
IF OBJECT_ID ('sp_cnt_employee','p') IS NOT NULL
DROP PROCEDURE sp_cnt_employee
GO

CREATE PROCEDURE sp_cnt_employee (@branch_id varchar(255) = null)
AS
BEGIN
	SET NOCOUNT ON
	IF @branch_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM branches WHERE branch_id = @branch_id)
	BEGIN
		RAISERROR (N'Chi nhánh có mã %s không tồn tại hoặc bạn đã nhập sai mã chi nhánh, xin hãy nhập lại',16,1,@branch_id)
		RETURN;
	END
	IF @branch_id IS NULL
	BEGIN
		SELECT branch_id, COUNT(branch_id) AS N'Tổng số nhân viên'
		FROM employees
		GROUP BY branch_id
	END
	ELSE
	BEGIN
		SELECT branch_id, COUNT(branch_id) AS N'Tổng số nhân viên'
		FROM employees
		WHERE branch_id = @branch_id
		GROUP BY branch_id
	END
END;
GO

EXEC sp_cnt_employee
EXEC sp_cnt_employee 'AHCA'

--Số lượng khách hàng tại các chi nhánh, nếu không nhập vào chi nhánh thì in ra số lượng khách của toàn bộ các chi nhánh
IF OBJECT_ID ('sp_cnt_customer','p') IS NOT NULL
DROP PROCEDURE sp_cnt_employee
GO
CREATE PROCEDURE sp_cnt_customer (@branch_id varchar(255) = null)
AS
BEGIN
	IF @branch_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM branches WHERE branch_id = @branch_id)
	BEGIN
		RAISERROR (N'Chi nhánh có mã %s không tồn tại hoặc bạn đã nhập sai mã chi nhánh, xin hãy nhập lại',16,1,@branch_id)
		RETURN;
	END
	IF @branch_id IS NULL
	BEGIN
		SELECT SUBSTRING(customer_id,1,4) AS N'Mã chi nhánh', COUNT(SUBSTRING(customer_id,1,4)) AS N'Tổng số khách hàng'
		FROM customers
		WHERE SUBSTRING(customer_id,1,4) IN (SELECT branch_id FROM branches)
		GROUP BY SUBSTRING(customer_id,1,4)
	END
	ELSE
	BEGIN
		SELECT SUBSTRING(customer_id,1,4) AS N'Mã chi nhánh', COUNT(SUBSTRING(customer_id,1,4)) AS N'Tổng số khách hàng'
		FROM customers
		WHERE SUBSTRING(customer_id,1,4) = @branch_id
		GROUP BY SUBSTRING(customer_id,1,4)
	END
END;
GO

EXEC sp_cnt_customer
EXEC sp_cnt_customer 'AHCA'

--Tổng số hàng tồn kho của mỗi product tại branch, tổng số product trên toàn chi nhánh, tổng số sản phẩm trong một chi nhánh
IF OBJECT_ID ('sp_cnt_product','p') IS NOT NULL
DROP PROCEDURE sp_cnt_product
GO
CREATE PROCEDURE sp_cnt_product (@branch_id VARCHAR(10) = null,@product_id VARCHAR(10) = null)
AS
BEGIN
	SET NOCOUNT ON
	IF @product_id IS NOT NULL and @branch_id IS NULL
	BEGIN
		SELECT i.product_id, p.product_name, p.description, SUM(i.quantity) AS N'Số lượng sản phẩm trên toàn chi nhánh'
		FROM inventories  i
		INNER JOIN products p ON i.product_id = p.product_id
		WHERE i.product_id = @product_id
		GROUP BY i.product_id, p.product_name, p.description
	END

	ELSE IF @product_id IS NULL AND @branch_id IS NOT NULL
	BEGIN
		SELECT branch_id, COUNT(branch_id) AS N'Tổng số sản phẩm', SUM(quantity) AS N'Tổng số lượng sản phẩm'
		FROM inventories
		WHERE branch_id = @branch_id
		GROUP BY branch_id
	END

	ELSE IF @branch_id IS NOT NULL AND @product_id IS NOT NULL
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM branches WHERE branch_id = @branch_id)
	   AND NOT EXISTS (SELECT 1 FROM products WHERE product_id = @product_id)
	    BEGIN
			RAISERROR (N'Mã chi nhánh và mã sản phẩm bạn nhập không tồn tại hoặc bạn đã nhập sai các mã, xin hãy nhập lại.',16,1);
			RETURN;
		END
		ELSE
		BEGIN
			SELECT product_id, branch_id, quantity
			FROM inventories
			WHERE product_id = @product_id AND branch_id = @branch_id
		END
	END
END;
GO

EXEC sp_cnt_product 'AHCA';
EXEC sp_cnt_product 'AHCA', 'PRD0003'
EXEC sp_cnt_product NULL,'PRD0003'
