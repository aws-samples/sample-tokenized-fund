/**
 * Validation utilities for asset price and proof of reserves data
 */

export interface ValidationResult {
    isValid: boolean;
    error?: string;
}

/**
 * Validates that a price value is a positive number
 * Requirements: 1.2
 */
export function validatePrice(price: any): ValidationResult {
    if (price === undefined || price === null) {
        return {
            isValid: false,
            error: 'Price is required'
        };
    }

    if (typeof price !== 'number') {
        return {
            isValid: false,
            error: 'Price must be a number'
        };
    }

    if (isNaN(price)) {
        return {
            isValid: false,
            error: 'Price must be a valid number'
        };
    }

    if (price <= 0) {
        return {
            isValid: false,
            error: 'Price must be a positive number'
        };
    }

    return { isValid: true };
}

/**
 * Validates that a collateral value is a positive number
 * Requirements: 3.2
 */
export function validateCollateral(collateralUsd: any): ValidationResult {
    if (collateralUsd === undefined || collateralUsd === null) {
        return {
            isValid: false,
            error: 'Collateral amount is required'
        };
    }

    if (typeof collateralUsd !== 'number') {
        return {
            isValid: false,
            error: 'Collateral amount must be a number'
        };
    }

    if (isNaN(collateralUsd)) {
        return {
            isValid: false,
            error: 'Collateral amount must be a valid number'
        };
    }

    if (collateralUsd <= 0) {
        return {
            isValid: false,
            error: 'Collateral amount must be a positive number'
        };
    }

    return { isValid: true };
}
