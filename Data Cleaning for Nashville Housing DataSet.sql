-- Cleaning Data in SQL -- 

Select *
From NashvilleHousing


-- Standarize Sale Date

Select SaleDate, CONVERT(Date, SaleDate)
FROM Project.dbo.NashvilleHousing

UPDATE Project.dbo.NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)  --The UPDATE statement is not making changes in the table and so we use ALTER


ALTER TABLE Project.dbo.NashvilleHousing 
Add SaleDateConverted Date;
 
UPDATE Project.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDateConverted
FROM Project.dbo.NashvilleHousing


-- Populate Property Address Data

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.propertyAddress, b.PropertyAddress) 
FROM NashvilleHousing a                    -- We are doing this because there are some null values in ProprtyAddress
JOIN NashvilleHousing b                    --ISNULL(What to replace, What to replace with)
ON a.ParcelID = b.ParcelID
 AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is NULL

UPDATE a
SET PropertyAddress = ISNULL(a.propertyAddress, b.PropertyAddress)
FROM NashvilleHousing a                   
JOIN NashvilleHousing b                    
ON a.ParcelID = b.ParcelID
 AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is NULL

-- Breaking out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM NashvilleHousing

SELECT  -- We are doing -1 as CHARINDEX was also giving ',' to us. Doing -1 select 1 position earlier i.e., no ','
SUBSTRING (PropertyAddress, 1, CHARINDEX(',' , PropertyAddress) -1) as Address
FROM NashvilleHousing  --CHARINDEX gives us te position number of the asked delibiter

SELECT 
SUBSTRING (PropertyAddress, 1, CHARINDEX(',' , PropertyAddress) -1) as Address,
SUBSTRING (PropertyAddress, CHARINDEX(',' , PropertyAddress) + 1, LEN(PropertyAddress)) as City
FROM NashvilleHousing

ALTER TABLE NashvilleHousing 
Add PropertySplitAddress Nvarchar(255);
 
UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING (PropertyAddress, 1, CHARINDEX(',' , PropertyAddress) -1) 

ALTER TABLE NashvilleHousing 
Add PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',' , PropertyAddress) +1, LEN(PropertyAddress))

SELECT *
FROM NashvilleHousing

SELECT OwnerAddress
FROM Project.dbo.NashvilleHousing

SELECT OwnerAddress,
SUBSTRING (OwnerAddress,1,CHARINDEX(',',OwnerAddress)-1) as OwnersAddress,
SUBSTRING (OwnerAddress,CHARINDEX(',',OwnerAddress)+1,CHARINDEX(',', OwnerAddress, CHARINDEX(',',OwnerAddress)-1)) as OwnersCity,
RIGHT(OwnerAddress, 3) as Ownerstate
FROM Project.dbo.NashvilleHousing

SELECT OwnerAddress,
SUBSTRING (OwnerAddress,1,CHARINDEX(',',OwnerAddress)-1) as OwnersAddress,
SUBSTRING (OwnerAddress,CHARINDEX(',',OwnerAddress)+1,CHARINDEX(',', OwnerAddress, CHARINDEX(',',OwnerAddress)-1)) as OwnersCity,
RIGHT(OwnerAddress, 3) as Ownerstate
FROM Project.dbo.NashvilleHousing
--We can also add the above into the table using ALTER TABLE

--In the city substring, we are finding the total length till GOODLETTSVILLE 
--and then subtract the Address part and so we get only city name and for it in SUBSTRING part we are starting from first comma 
--and end the SUBSTRING at (ADDRESS-CITY).
SELECT CHARINDEX(',', OwnerAddress, CHARINDEX(',', OwnerAddress) + 1), CHARINDEX(',', OwnerAddress) - 2,CHARINDEX(',', OwnerAddress, CHARINDEX(',', OwnerAddress) + 1) - CHARINDEX(',', OwnerAddress) - 2,
SUBSTRING(OwnerAddress, 1, CHARINDEX(',', OwnerAddress) - 1) AS Address,
SUBSTRING(OwnerAddress, CHARINDEX(',', OwnerAddress) + 2, CHARINDEX(',', OwnerAddress, CHARINDEX(',', OwnerAddress) + 1) - CHARINDEX(',', OwnerAddress) - 2) AS City,
SUBSTRING(OwnerAddress, CHARINDEX(',', OwnerAddress, CHARINDEX(',', OwnerAddress) + 1) + 2, LEN(OwnerAddress)) AS State
FROM Project.dbo.NashvilleHousing

--Splitting the OwnerAddress into Address, City and State using PARSENAME.
SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'),3) AS Address,
PARSENAME(REPLACE(OwnerAddress, ',', '.'),2) AS City,
PARSENAME(REPLACE(OwnerAddress, ',', '.'),1) AS State
FROM Project.dbo.NashvilleHousing


ALTER TABLE Project.dbo.NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);
UPDATE Project.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)

ALTER TABLE Project.dbo.NashvilleHousing
Add OwnerSplitCity Nvarchar(255);
UPDATE Project.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)

ALTER TABLE Project.dbo.NashvilleHousing
Add OwnerSplitState Nvarchar(255);
UPDATE Project.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)


-- Change Y and N to Yes and No in "Sold as Vacant" feild 

SELECT Distinct(SoldAsVacant), COUNT(SoldAsVacant)
FROM Project.dbo.NashvilleHousing
GROUP BY SoldAsVacant

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant= 'Y' THEN 'Yes'
     WHEN SoldAsVacant= 'N' THEN 'No'
ELSE SoldAsVacant
END
FROM Project.dbo.NashvilleHousing

UPDATE Project.dbo.NashvilleHousing
SET SoldAsVacant= CASE WHEN SoldAsVacant= 'Y' THEN 'Yes'
	WHEN SoldAsVacant= 'N' THEN 'No'
	ELSE SoldAsVacant
	END 


--Remove Duplicates


SELECT ParcelID, COUNT(ParcelID)  --Checking for duplicates 
FROM Project.dbo.NashvilleHousing
GROUP BY ParcelID
HAVING COUNT(ParcelID)>1

WITH Row_Num_CTE AS(
SELECT *,     --using the partition by and row number cluase we are identifying the duplicates and they are assigned 2,3,...
ROW_NUMBER()  --This is because the number starts from 1 when the element value in column in partition by changes and so
OVER (		  -- the value is 1 for when elements are different bu turns to 2,3,.. when element is same and hence is duplicate.
PARTITION BY ParcelID, PropertyAddress, SalePrice,
SaleDate, LegalReference 
ORDER BY UniqueID) row_num
FROM Project.dbo.NashvilleHousing
)
DELETE            --Deleting the duplicates present in the data. 
FROM Row_Num_CTE  --We can check the dupplicates by running the same query but using select instead of delete.
WHERE row_num >1



--Delete Unused Columns

ALTER TABLE Project.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE Project.dbo.NashvilleHousing  -- We have wrote new quesry to drop SaleDate as it can't be used above as owneradress
DROP COLUMN SaleDate                      -- and other column are deleted earlier and they might not be found when we add SaleDate column 
                                          -- and it will give us the error.

SELECT *
FROM Project.dbo.NashvilleHousing
