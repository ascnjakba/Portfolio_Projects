-- Cleaning data in SQL Queries
USE profolio_project;
SELECT *
FROM nashvilleHousing;
-- Standardize Date Format
ALTER TABLE nashvilleHousing
MODIFY SaleDate DATE;
-- Populate property address data
UPDATE nashvilleHousing
SET PropertyAddress =(
	SELECT temp.address
    FROM(
		SELECT IFNULL(n1.PropertyAddress, n2.PropertyAddress) AS address
        FROM nashvilleHousing n1
		JOIN nashvilleHousing n2 
			ON n1.ParcelID = n2.ParcelID AND n1.UniqueID <> n2.UniqueID
		LIMIT 1
	) temp
)
WHERE PropertyAddress IS NULL;
-- Breaking out Address into individual columns(Address, City, State)
SELECT 
	SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, (INSTR(PropertyAddress, ',') - 1)) AS addressCity,
    SUBSTRING(PropertyAddress, 1, INSTR(PropertyAddress, ',') - 1) AS address
FROM nashvilleHousing;

ALTER TABLE nashvilleHousing
ADD COLUMN address VARCHAR(255) AFTER PropertyAddress;
UPDATE nashvilleHousing
SET address =  SUBSTRING(PropertyAddress, 1, INSTR(PropertyAddress, ',') - 1);
ALTER TABLE nashvilleHousing
ADD COLUMN addressCity VARCHAR(255) AFTER address;
UPDATE nashvilleHousing
SET addressCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, (INSTR(PropertyAddress, ',') - 1));
-- Change Y and N to Yes and No in 'Sold as Vacant' field
SELECT 
	DISTINCT SoldAsVacant,
    COUNT(SoldAsVacant)
FROM nashvilleHousing
GROUP BY SoldAsVacant;

UPDATE nashvilleHousing
SET SoldAsVacant = 
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
	END;
-- Remove Duplicate
-- Window Function
WITH cte AS(
SELECT 
	*,
    ROW_NUMBER() OVER (
    PARTITION BY 
		ParcelID,
        address,
        SalePrice,
        SaleDate,
        LegalReference
	ORDER BY 
		UniqueID) AS row_num
FROM nashvilleHousing
)
-- 由于CTE不可更新，需要参考原表删除行
DELETE FROM nashvilleHousing
USING nashvilleHousing
JOIN cte USING (UniqueID)
WHERE row_num > 1;
-- Delete unused columns
ALTER TABLE nashvilleHousing
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress;
