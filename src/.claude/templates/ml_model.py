"""
ML model implementation for [MODEL_PURPOSE].

This module provides a [MODEL_TYPE] model for [SPECIFIC_TASK].

Key components:
- Model architecture and training logic
- Data preprocessing and validation  
- Performance evaluation and metrics
"""

# ----------------------------------------
# Step 1 – Import and Setup
# ----------------------------------------

# Substep 1.1 – Standard library imports ______________________
import os
import sys
from typing import Dict, List, Optional, Union, Tuple, Any
import logging

# Substep 1.2 – External library imports ______________________
import numpy as np
import pandas as pd
from sklearn.base import BaseEstimator, TransformerMixin
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import accuracy_score, classification_report
from sklearn.preprocessing import StandardScaler

# Substep 1.3 – Internal imports ______________________
# Add internal imports here

# ----------------------------------------
# Step 2 – Constants and Configuration
# ----------------------------------------

# Model hyperparameters
DEFAULT_RANDOM_STATE = 42
DEFAULT_TEST_SIZE = 0.2
DEFAULT_CV_FOLDS = 5

# Logging configuration
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ----------------------------------------
# Step 3 – Main Model Implementation
# ----------------------------------------

class MLModel(BaseEstimator):
    """Machine learning model for [SPECIFIC_TASK].
    
    This model implements [ALGORITHM/APPROACH] for [PROBLEM_TYPE].
    Compatible with scikit-learn's estimator interface.
    
    Parameters:
        param1 (float): Description of parameter. Defaults to 1.0.
        param2 (int): Description of parameter. Defaults to 10.
        random_state (int): Random seed for reproducibility. Defaults to 42.
        
    Attributes:
        is_fitted_ (bool): Whether the model has been fitted.
        feature_names_ (List[str]): Names of input features.
        n_features_ (int): Number of input features.
        
    Example:
        >>> model = MLModel(param1=0.5, param2=20)
        >>> model.fit(X_train, y_train)
        >>> predictions = model.predict(X_test)
    """
    
    def __init__(
        self,
        param1: float = 1.0,
        param2: int = 10,
        random_state: int = DEFAULT_RANDOM_STATE
    ):
        self.param1 = param1
        self.param2 = param2
        self.random_state = random_state
        
        # Initialize internal state
        self.is_fitted_ = False
        self.feature_names_ = None
        self.n_features_ = None
        self._model = None
    
    def fit(self, X: np.ndarray, y: np.ndarray) -> 'MLModel':
        """Fit the model to training data.
        
        Args:
            X: Training features of shape (n_samples, n_features).
            y: Training targets of shape (n_samples,).
            
        Returns:
            Self for method chaining.
            
        Raises:
            ValueError: If input data is invalid.
        """
        # ✅ Validate inputs
        X, y = self._validate_input(X, y)
        
        # 🔄 Fit model
        logger.info(f"Fitting model with {X.shape[0]} samples, {X.shape[1]} features")
        
        # Store feature information
        self.n_features_ = X.shape[1]
        if hasattr(X, 'columns'):
            self.feature_names_ = list(X.columns)
        
        # Fit your model here
        # self._model = SomeAlgorithm(param1=self.param1, param2=self.param2)
        # self._model.fit(X, y)
        
        self.is_fitted_ = True
        
        # 📊 Log fitting completion
        logger.info("Model fitting completed successfully")
        return self
    
    def predict(self, X: np.ndarray) -> np.ndarray:
        """Make predictions on new data.
        
        Args:
            X: Features of shape (n_samples, n_features).
            
        Returns:
            Predictions of shape (n_samples,).
            
        Raises:
            ValueError: If model is not fitted or input is invalid.
        """
        # ✅ Validate inputs
        self._check_is_fitted()
        X = self._validate_input(X, check_target=False)
        
        # 🔄 Make predictions
        # predictions = self._model.predict(X)
        
        # Placeholder prediction
        predictions = np.zeros(X.shape[0])
        
        # 📊 Return predictions
        return predictions
    
    def predict_proba(self, X: np.ndarray) -> np.ndarray:
        """Predict class probabilities.
        
        Args:
            X: Features of shape (n_samples, n_features).
            
        Returns:
            Class probabilities of shape (n_samples, n_classes).
        """
        # ✅ Validate inputs
        self._check_is_fitted()
        X = self._validate_input(X, check_target=False)
        
        # 🔄 Predict probabilities
        # probabilities = self._model.predict_proba(X)
        
        # Placeholder probabilities
        probabilities = np.ones((X.shape[0], 2)) * 0.5
        
        # 📊 Return probabilities
        return probabilities
    
    def score(self, X: np.ndarray, y: np.ndarray) -> float:
        """Calculate model score on test data.
        
        Args:
            X: Test features of shape (n_samples, n_features).
            y: Test targets of shape (n_samples,).
            
        Returns:
            Model accuracy score.
        """
        # ✅ Validate inputs
        predictions = self.predict(X)
        
        # 🔄 Calculate score
        score = accuracy_score(y, predictions)
        
        # 📊 Return score
        return score
    
    def _validate_input(self, X: np.ndarray, y: np.ndarray = None, check_target: bool = True) -> Union[np.ndarray, Tuple[np.ndarray, np.ndarray]]:
        """Validate input data.
        
        Args:
            X: Input features.
            y: Input targets (optional).
            check_target: Whether to validate targets.
            
        Returns:
            Validated X and y (if provided).
            
        Raises:
            ValueError: If input validation fails.
        """
        # ✅ Check X
        if X is None or len(X) == 0:
            raise ValueError("X cannot be None or empty")
        
        # Convert to numpy if needed
        if hasattr(X, 'values'):
            X = X.values
        
        X = np.asarray(X)
        
        if len(X.shape) != 2:
            raise ValueError(f"X must be 2D array, got shape {X.shape}")
        
        # Check feature count consistency
        if self.is_fitted_ and X.shape[1] != self.n_features_:
            raise ValueError(f"X has {X.shape[1]} features, expected {self.n_features_}")
        
        # ✅ Check y if provided
        if check_target and y is not None:
            if hasattr(y, 'values'):
                y = y.values
            
            y = np.asarray(y)
            
            if len(y) != len(X):
                raise ValueError(f"X and y must have same length: {len(X)} vs {len(y)}")
            
            return X, y
        
        return X
    
    def _check_is_fitted(self):
        """Check if model is fitted.
        
        Raises:
            ValueError: If model is not fitted.
        """
        if not self.is_fitted_:
            raise ValueError("Model must be fitted before making predictions")

# ----------------------------------------
# Step 4 – Data Preprocessing Pipeline
# ----------------------------------------

class DataPreprocessor(BaseEstimator, TransformerMixin):
    """Data preprocessing pipeline for ML model.
    
    Handles feature scaling, encoding, and validation.
    Compatible with scikit-learn's transformer interface.
    
    Parameters:
        scale_features (bool): Whether to scale numerical features. Defaults to True.
        handle_missing (str): How to handle missing values ('drop', 'mean', 'median'). Defaults to 'mean'.
        
    Attributes:
        scaler_ (StandardScaler): Fitted feature scaler.
        feature_names_ (List[str]): Names of processed features.
    """
    
    def __init__(self, scale_features: bool = True, handle_missing: str = 'mean'):
        self.scale_features = scale_features
        self.handle_missing = handle_missing
        
        # Initialize internal state
        self.scaler_ = None
        self.feature_names_ = None
        self.is_fitted_ = False
    
    def fit(self, X: pd.DataFrame, y: np.ndarray = None) -> 'DataPreprocessor':
        """Fit preprocessor to training data.
        
        Args:
            X: Input features.
            y: Target values (ignored).
            
        Returns:
            Self for method chaining.
        """
        # ✅ Validate inputs
        if X is None or len(X) == 0:
            raise ValueError("X cannot be None or empty")
        
        # 🔄 Fit preprocessing steps
        if self.scale_features:
            self.scaler_ = StandardScaler()
            self.scaler_.fit(X.select_dtypes(include=[np.number]))
        
        self.feature_names_ = list(X.columns) if hasattr(X, 'columns') else None
        self.is_fitted_ = True
        
        # 📊 Return self
        return self
    
    def transform(self, X: pd.DataFrame) -> np.ndarray:
        """Transform input data.
        
        Args:
            X: Input features to transform.
            
        Returns:
            Transformed features.
        """
        # ✅ Validate inputs
        if not self.is_fitted_:
            raise ValueError("Preprocessor must be fitted before transforming")
        
        # 🔄 Apply transformations
        X_transformed = X.copy()
        
        # Handle missing values
        if self.handle_missing == 'mean':
            X_transformed = X_transformed.fillna(X_transformed.mean())
        elif self.handle_missing == 'median':
            X_transformed = X_transformed.fillna(X_transformed.median())
        elif self.handle_missing == 'drop':
            X_transformed = X_transformed.dropna()
        
        # Scale features
        if self.scale_features and self.scaler_ is not None:
            numeric_cols = X_transformed.select_dtypes(include=[np.number]).columns
            X_transformed[numeric_cols] = self.scaler_.transform(X_transformed[numeric_cols])
        
        # 📊 Return transformed data
        return X_transformed.values if hasattr(X_transformed, 'values') else X_transformed

# ----------------------------------------
# Step 5 – Model Evaluation
# ----------------------------------------

def evaluate_model(model: MLModel, X_test: np.ndarray, y_test: np.ndarray, verbose: bool = True) -> Dict[str, float]:
    """Evaluate model performance on test data.
    
    Args:
        model: Fitted ML model.
        X_test: Test features.
        y_test: Test targets.
        verbose: Whether to print detailed results.
        
    Returns:
        Dictionary containing evaluation metrics.
    """
    # ✅ Validate inputs
    if not hasattr(model, 'predict'):
        raise ValueError("Model must have predict method")
    
    # 🔄 Make predictions
    predictions = model.predict(X_test)
    
    # Calculate metrics
    accuracy = accuracy_score(y_test, predictions)
    
    metrics = {
        'accuracy': accuracy,
        'n_samples': len(y_test),
        'n_features': X_test.shape[1] if hasattr(X_test, 'shape') else 0
    }
    
    # 📊 Print results if verbose
    if verbose:
        print("\n" + "="*50)
        print("MODEL EVALUATION RESULTS")
        print("="*50)
        print(f"Accuracy: {accuracy:.4f}")
        print(f"Test samples: {metrics['n_samples']}")
        print(f"Features: {metrics['n_features']}")
        print("\nClassification Report:")
        print(classification_report(y_test, predictions))
    
    return metrics

# ----------------------------------------
# Step 6 – Module Execution
# ----------------------------------------

if __name__ == "__main__":
    # Example usage and testing
    logger.info("Running ML model example...")
    
    # Generate sample data
    np.random.seed(DEFAULT_RANDOM_STATE)
    X_sample = np.random.randn(100, 5)
    y_sample = np.random.randint(0, 2, 100)
    
    # Split data
    X_train, X_test, y_train, y_test = train_test_split(
        X_sample, y_sample, test_size=DEFAULT_TEST_SIZE, random_state=DEFAULT_RANDOM_STATE
    )
    
    # Train model
    model = MLModel()
    model.fit(X_train, y_train)
    
    # Evaluate model
    metrics = evaluate_model(model, X_test, y_test)
    
    logger.info(f"Example completed. Accuracy: {metrics['accuracy']:.4f}")