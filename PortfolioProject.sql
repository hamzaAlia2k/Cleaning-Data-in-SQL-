--### Checking the data
--### note: I will add three Hashtags in comments to specifies the comments
select * 
from Nashville.dbo.NashvilleHousing 

--### A liitle exploring here in SQL 
--### starting with Sale Date feature
select SaleDate 
from Nashville.dbo.NashvilleHousing 
-- ### for further manipulation, I need to convert the date column from datetime datatype to only date, no need for time :)
select SaleDate,cast(SaleDate as date)
from Nashville.dbo.NashvilleHousing  

-- ###updating the date column
update NashvilleHousing
set SaleDate = CONVERT(date, SaleDate)

select SaleDate from NashvilleHousing

--### another way to add:
alter table NashvilleHousing
add SaleDateConverted date;

update NashvilleHousing
set SaleDateConverted = CONVERT(date, SaleDate)

select SaleDateConverted
from NashvilleHousing -- ### it worked !!
------------------------------------------------------------------------------------------------------
--- ### Populate Property Address data
select PropertyAddress
from Nashville.dbo.NashvilleHousing --### we can see that the full address is in a single cell, which can lead to bad future analysis

--###checking if there is null Addresses:
select PropertyAddress
from Nashville.dbo.NashvilleHousing
where PropertyAddress is null -- ### we can see that there is 29 missing addresses

--### Handling Missing values in addresses 
select *
from Nashville.dbo.NashvilleHousing
--where PropertyAddress is null
order by ParcelID
--### having same ParcelID means having same address, here are two houses that have same ParcelID, we can see that they share same address
select *
from Nashville.dbo.NashvilleHousing
where ParcelID = '015 14 0 060.00'

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
from Nashville.dbo.NashvilleHousing as a
inner join Nashville.dbo.NashvilleHousing as b
on a.ParcelID = b.ParcelID 
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null 
--### using the upper code we get the addresses for the missing ones from the joiner table


update a
set PropertyAddress = isnull(a.PropertyAddress, b.PropertyAddress)
from Nashville.dbo.NashvilleHousing as a
inner join Nashville.dbo.NashvilleHousing as b
on a.ParcelID = b.ParcelID 
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null 
--### we have solved the issue !
------------------------------------------------------------------------------------------------------------------
--### if we look at the addresses we find that the whole address is in one column, it would be much better if we separate that addresses

select PropertyAddress
from Nashville.dbo.NashvilleHousing
--### we need to separate the cells by spaces - so the delimiter is the space 
select PropertyAddress,
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) as address,
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) as address2
from Nashville.dbo.NashvilleHousing

--### adding the two columns:
alter table NashvilleHousing 
add PropertySplitAddress nvarchar(255);

update NashvilleHousing 
set PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) 
--##
alter table NashvilleHousing
add PropertySplitCity nvarchar(255);

update NashvilleHousing
set PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))

select PropertySplitAddress,PropertySplitCity 
from Nashville.dbo.NashvilleHousing
--### we have solved the issue !
-------------------------------------------------------------------------------------------------------------------------
--#### if we look at the owner address we will find the same issue from the PropertyAddress, so we need to split
select OwnerAddress
from Nashville.dbo.NashvilleHousing
--### now i am going to split the cells using PARSENAME
select 
OwnerAddress,
PARSENAME(replace(OwnerAddress, ',','.'),3), 
PARSENAME(replace(OwnerAddress, ',','.'),2),
PARSENAME(replace(OwnerAddress, ',','.'),1)
from Nashville.dbo.NashvilleHousing

alter table NashvilleHousing 
add OwnerSplitAddress nvarchar(255);

update NashvilleHousing 
set OwnerSplitAddress = PARSENAME(replace(OwnerAddress, ',','.'),3) 
--##
alter table NashvilleHousing
add OwnerSplitCity nvarchar(255);

update NashvilleHousing
set OwnerSplitCity = PARSENAME(replace(OwnerAddress, ',','.'),2)
--##
alter table NashvilleHousing 
add OwnerSplitState nvarchar(255);

update NashvilleHousing 
set OwnerSplitState = PARSENAME(replace(OwnerAddress, ',','.'),1)

--### checking:
select OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
from Nashville.dbo.NashvilleHousing

--### we have solved the issue !
---------------------------------------------------------------------------------------------------------------------
--#### when I take a look on SoldAsVacant I found that there is 'N' as a no and 'Y' as a yes:
select distinct(SoldAsVacant), count(SoldAsVacant)
from Nashville.dbo.NashvilleHousing
group by SoldAsVacant
order by 2 

--### let's map Y and N into yes and no:
select SoldAsVacant,
case 
	when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
else
	SoldAsVacant --## keep 
end
from Nashville.dbo.NashvilleHousing

update NashvilleHousing
set SoldAsVacant = 
case 
	when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
else
	SoldAsVacant --## keep 
end 
--### we have solved the issue !
------------------------------------------------------------------------------------------------------------------
--### now we need to Remove the Duplicates 
--### combining a duplicated observations by the unique attributs , (unique values should be unique to each observation) 
with RowNumCTE as (
select *, 
	ROW_NUMBER() over(
	partition by ParcelId,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 Order by UniqueID) as raw_num

from Nashville.dbo.NashvilleHousing
--order by ParcelID
)
select * from RowNumCTE
where raw_num > 1
order by ParcelID
--## we can see 104 duplicated obseravtions


--delete from RowNumCTE
--where raw_num > 1

--### we have solved the issue !
select * from Nashville.dbo.NashvilleHousing --### duplicated obseravtions were Removed successfully !
------------------------------------------------------------------------------------------------------------------

---###Removing un-needed column 
select * 
from Nashville.dbo.NashvilleHousing
--### we have splitted the PropertyAddresses and OwnerAddress 
--### so we need to delete the original columns

alter table Nashville.dbo.NashvilleHousing
drop column ownerAddress, propertyAddress

--## we have converted the saleDate column from Datetime to Date,
alter table Nashville.dbo.NashvilleHousing
drop column SaleDate

select * from Nashville.dbo.NashvilleHousing