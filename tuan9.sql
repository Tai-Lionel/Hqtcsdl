--1.  Trong SQL Server, tạo thiết bị backup có tên adv2008back lưu trong thư mục 
--T:\backup\adv2008back.bak
EXEC sp_addumpdevice 'disk', 'adv2008back', 'T:\backup\adv2008back.bak'
--2.  Attach CSDL AdventureWorks2008, chọn mode recovery cho CSDL này là full, rồi 
--thực hiện full backup vào thiết bị backup vừa tạo
alter database AdventureWorks2008R2
set recovery full

backup database AdventureWorks2008R2
to adv2008back 
-- to disk = 'T:\backup\adv2008back.bak'
with description = 'AdventureWorks2008R2 FULL Backup'
go
--3.  Mở CSDL AdventureWorks2008, tạo một transaction giảm giá tất cả mặt hàng xe 
--đạp trong bảng Product xuống $15 nếu tổng trị giá các mặt hàng xe đạp không thấp 
--hơn 60%.
-- Công ty AdventureWorks kinh doanh các mặt hàng gì?
select *
from Production.ProductCategory
where Name = 'Bikes'
-- Có máy loại xe đạp, kể tên
select *
from Production.ProductSubcategory
where ProductCategoryID = 1
-- Lọc ra các mặt hàng là xe đạp
select ProductID, Name, ListPrice
from Production.Product
where ProductSubcategoryID in (
	select ProductSubcategoryID
	from Production.ProductSubcategory
	where ProductCategoryID = 1
)
-- ProductID = 749 => ListPrice = 3578.27

use AdventureWorks2008R2
begin tran
declare @TongXeDap money, @Tong money
set @TongXeDap = (
	select sum(ListPrice)
	from Production.Product
	where ProductSubcategoryID in (
		select ProductSubcategoryID
		from Production.ProductCategory
		where ProductCategoryID = 1
	)
)
set @tong = (
	select sum(ListPrice)
	from Production.Product
)
if @TongXeDap / @Tong >= 0.6
	begin
		update Production.Product
		set ListPrice = ListPrice - 15
		where ProductSubcategoryID in (
			select ProductSubcategoryID
			from Production.ProductSubcategory
			where ProductSubcategoryID = 1
		)
		commit tran
	end
else
	rollback tran
go
-- xem lại giá trị của xe đạp sau khi giảm
select ProductID, Name, ListPrice
from Production.Product
where ProductSubcategoryID in (
	select ProductSubcategoryID
	from Production.ProductSubcategory
	where ProductSubcategoryID = 1
)