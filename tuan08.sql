--module 6. role and permission
--1)  Đăng nhập vào  SQL  bằng SQL  Server authentication, tài khoản sa.  Sử dụng TSQL
--2)  Tạo hai login SQL server Authentication User2 và  User3
create login User2 with password = 'keepoath', default_database=AdventureWorks2008R2
create login User3 with password = 'keepoath', default_database=AdventureWorks2008R2
--3)  Tạo một database user User2 ứng với login User2 và một database user   User3
--ứng với login User3 trên CSDL AdventureWorks2008.
use AdventureWorks2008R2
create user User2 for login User2 
create user User3 for login User3
--4)  Tạo 2 kết nối đến server thông qua login  User2  và  User3, sau đó thực hiện các 
--thao tác truy cập CSDL  của 2 user  tương ứng (VD: thực hiện  câu Select). Có thực 
--hiện được không?
select * from Sales.SalesOrderHeader
-- không làm được bởi vì chưa cấp quyền
-- The SELECT permission was denied on the object 'SalesOrderHeader', database 'AdventureWorks2008R2', schema 'Sales'.
--5)  Gán quyền select trên Employee cho User2, kiểm tra kết quả.  Xóa quyền select 
--trên Employee cho User2. Ngắt 2 kết nối của User2 và  User3
grant select on HumanResources.Employee to user2 -- user 2 làm được câu lệnh select trên bảng employee
revoke select on HumanResources.Employee from user2 -- user 2 không làm được câu lệnh select trên bảng Employee nữa
--6)  Trở lại kết nối của sa, tạo một user-defined database Role tên Employee_Role trên 
--CSDL  AdventureWorks2008,  sau  đó  gán  các  quyền  Select,  Update,  Delete  cho 
--Employee_Role.
create role Employee_Role
grant select, update, delete on HumanResources.Employee to Employee_Role
--7)  Thêm các  User2  và  User3  vào  Employee_Role.  Tạo  lại  2  kết  nối  đến  server  thông 
--qua login User2 và User3 thực hiện các thao tác  sau:
exec sp_addrolemember Employee_Role, User2
exec sp_addrolemember Employee_Role, User3
--a)  Tại kết nối với User2, thực hiện câu lệnh Select để xem thông tin của bảng 
--Employee
select * from HumanResources.Employee
--b)  Tại kết nối của User3, thực hiện cập nhật JobTitle=’Sale Manager’ của  nhân 
--viên có BusinessEntityID=1
update HumanResources.Employee
set JobTitle = 'Sale Manager'
where BusinessEntityID = 1
--c)  Tại kết nối User2, dùng câu lệnh Select xem lại kết  quả.
select * from HumanResources.Employee
--d)  Xóa role Employee_Role, (quá trình xóa role ra sao ?
drop role Employee_Role
--The role has members. It must be empty before it can be dropped.
exec sp_droprolemember Employee_Role, User2
exec sp_droprolemember Employee_Role, User3
drop role Employee_Role

--module 7. transaction
--1)  Thêm  vào  bảng  Department  một  dòng  dữ  liệu  tùy  ý  bằng  câu  lệnh 
--INSERT..VALUES…
select * from HumanResources.Department
insert into HumanResources.Department (DepartmentID, Name, GroupName, ModifiedDate) 
values (17, 'Entertainment', 'Entertainment', GETDATE())
set identity_insert HumanResources.Department on
--a)  Thực hiện lệnh chèn thêm vào bảng Department một dòng dữ liệu tùy ý bằng 
--cách thực hiện lệnh Begin tran và Rollback, dùng câu lệnh Select * From 
--Department xem kết quả.
begin tran t1
insert into HumanResources.Department (DepartmentID, Name, GroupName, ModifiedDate) 
values (18, 'Manufacturing', 'Manufacturing', GETDATE())
rollback tran t1
-- kiem tra
select * from HumanResources.Department -- không có dòng nào được thêm vào bảng department
--b)  Thực hiện câu lệnh trên với lệnh Commit và kiểm tra kết  quả.
begin tran t1
insert into HumanResources.Department (DepartmentID, Name, GroupName, ModifiedDate) 
values (18, 'Manufacturing', 'Manufacturing', GETDATE())
commit tran t1
-- kiem tra
select * from HumanResources.Department -- thêm được department vào bảng Department
--2)  Tắt chế độ autocommit của SQL Server (SET IMPLICIT_TRANSACTIONS 
--ON). Tạo đoạn batch gồm các thao  tác:
set implicit_transactions on
--  Thêm một dòng vào bảng  Department
--  Tạo một bảng Test (ID int, Name  nvarchar(10))
--  Thêm một dòng vào Test
--  ROLLBACK;
begin tran t2
insert into HumanResources.Department (DepartmentID, Name, GroupName, ModifiedDate)
values (19, 'Agriculture', 'Agriculture', GETDATE())
create table Test (ID int, Name nvarchar(10))
insert into Test (ID, Name) values (1, 'TaiLionel')
rollback
--  Xem dữ liệu ở bảng Department và Test để kiểm tra dữ liệu, giải thích kết 
--quả
select * from HumanResources.Department --không có gì thay đổi
select * from Test -- không có bảng Test (bảng Test không được tạo ra bởi vì transaction bị rollback)
set implicit_transactions off

--3)  Viết  đoạn  batch  thực  hiện  các  thao  tác  sau  (lưu  ý  thực  hiện  lệnh  SET 
--XACT_ABORT ON: nếu câu lệnh T-SQL làm phát sinh lỗi run-time, toàn bộ giao 
--dịch được chấm dứt và  Rollback)
set xact_abort on
--  Câu lệnh SELECT với phép chia 0 :SELECT 1/0 as  Dummy
--  Cập nhật một dòng trên bảng Department với DepartmentID=’9’ (id này 
--không tồn  tại)
--  Xóa một dòng không tồn tại trên bảng Department  (DepartmentID =’66’)
--  Thêm một dòng bất kỳ vào bảng  Department
--  COMMIT;
begin tran
select 1/0 as Dummy
update HumanResources.Department
set Name = 'Do you want to build a snowman'
where DepartmentID = 27 --ID này không tồn tại
delete from HumanResources.Department
where DepartmentID = 66
insert into HumanResources.Department (DepartmentID, Name, GroupName, ModifiedDate)
values (20, 'Literature', 'Literature', GETDATE())
commit
--Thực thi đoạn batch, quan sát kết quả và các thông báo lỗi và giải thích kết quả.
select * from HumanResources.Department
--4)  Thực  hiện  lệnh  SET  XACT_ABORT  OFF  (những  câu  lệnh  lỗi  sẽ  rollback, 
--transaction vẫn tiếp tục) sau đó thực thi lại các thao tác của đoạn batch ở câu 3. Quan 
--sát kết quả và giải thích kết  quả?
SET XACT_ABORT OFF
begin tran
select 1/0 as Dummy
update HumanResources.Department
set Name = 'Do you want to build a snowman'
where DepartmentID = 27 --ID này không tồn tại
delete from HumanResources.Department
where DepartmentID = 66
insert into HumanResources.Department (DepartmentID, Name, GroupName, ModifiedDate)
values (20, 'Literature', 'Literature', GETDATE())
commit
--Thực thi đoạn batch, quan sát kết quả và các thông báo lỗi và giải thích kết quả.
select * from HumanResources.Department


