"""
Data processing pipeline for [DATA_SOURCE] datasets.

This module provides comprehensive data processing capabilities for [DOMAIN_SPECIFIC] 
machine learning workflows including cleaning, validation, and feature engineering.

Key components:
- Data loading and validation
- Feature engineering and selection
- Data quality checks and reporting
"""

# ----------------------------------------
# Step 1 – Import and Setup
# ----------------------------------------

# Substep 1.1 – Standard library imports ______________________
import os
import sys
from typing import Dict, List, Optional, Union, Tuple, Any
import logging
from pathlib import Path

# Substep 1.2 – External library imports ______________________
import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler, LabelEncoder, OneHotEncoder
from sklearn.feature_selection import SelectKBest, f_classif
from sklearn.model_selection import train_test_split

# Substep 1.3 – Internal imports ______________________
# Add internal imports here

# ----------------------------------------
# Step 2 – Constants and Configuration
# ----------------------------------------

# Data processing parameters
DEFAULT_MISSING_THRESHOLD = 0.5  # Drop columns with >50% missing
DEFAULT_CORRELATION_THRESHOLD = 0.95  # Drop highly correlated features
DEFAULT_RANDOM_STATE = 42

# File paths and formats
SUPPORTED_FORMATS = ['.csv', '.parquet', '.json', '.excel']
DEFAULT_ENCODING = 'utf-8'

# Logging configuration
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ----------------------------------------
# Step 3 – Main Data Processor Class
# ----------------------------------------

class DataProcessor:
    """Comprehensive data processing pipeline.
    
    Handles data loading, cleaning, validation, and feature engineering
    for machine learning workflows.
    
    Parameters:
        missing_threshold (float): Threshold for dropping columns with missing values.
        correlation_threshold (float): Threshold for dropping correlated features.
        scale_features (bool): Whether to scale numerical features.
        encode_categorical (bool): Whether to encode categorical features.
        random_state (int): Random seed for reproducibility.
        
    Attributes:
        is_fitted_ (bool): Whether the processor has been fitted.
        feature_names_ (List[str]): Names of processed features.
        dropped_columns_ (List[str]): Names of dropped columns.
        scalers_ (Dict): Fitted scalers for numerical features.
        encoders_ (Dict): Fitted encoders for categorical features.
        
    Example:
        >>> processor = DataProcessor(missing_threshold=0.3)
        >>> X_processed = processor.fit_transform(X_raw)
        >>> X_test_processed = processor.transform(X_test_raw)
    """
    
    def __init__(
        self,
        missing_threshold: float = DEFAULT_MISSING_THRESHOLD,
        correlation_threshold: float = DEFAULT_CORRELATION_THRESHOLD,
        scale_features: bool = True,
        encode_categorical: bool = True,
        random_state: int = DEFAULT_RANDOM_STATE
    ):
        self.missing_threshold = missing_threshold
        self.correlation_threshold = correlation_threshold
        self.scale_features = scale_features
        self.encode_categorical = encode_categorical
        self.random_state = random_state
        
        # Initialize internal state
        self.is_fitted_ = False
        self.feature_names_ = None
        self.dropped_columns_ = []
        self.scalers_ = {}
        self.encoders_ = {}
        self.feature_stats_ = {}
    
    def fit(self, X: pd.DataFrame, y: pd.Series = None) -> 'DataProcessor':
        """Fit the data processor to training data.
        
        Args:
            X: Input features dataframe.
            y: Target values (optional, used for feature selection).
            
        Returns:
            Self for method chaining.
            
        Raises:
            ValueError: If input data is invalid.
        """
        # ✅ Validate inputs
        X = self._validate_input(X)
        
        logger.info(f"Fitting data processor on {X.shape[0]} samples, {X.shape[1]} features")
        
        # 🔄 Process data step by step
        X_processed = X.copy()
        
        # Step 1: Handle missing values
        X_processed = self._fit_handle_missing(X_processed)
        
        # Step 2: Handle categorical features
        if self.encode_categorical:
            X_processed = self._fit_encode_categorical(X_processed)
        
        # Step 3: Handle numerical features
        if self.scale_features:
            X_processed = self._fit_scale_numerical(X_processed)
        
        # Step 4: Feature selection
        if y is not None:
            X_processed = self._fit_feature_selection(X_processed, y)
        
        # Step 5: Remove highly correlated features
        X_processed = self._fit_remove_correlated(X_processed)
        
        # Store final feature information
        self.feature_names_ = list(X_processed.columns)
        self.is_fitted_ = True
        
        # 📊 Log completion
        logger.info(f"Data processor fitted. Final features: {len(self.feature_names_)}")
        logger.info(f"Dropped columns: {len(self.dropped_columns_)}")
        
        return self
    
    def transform(self, X: pd.DataFrame) -> pd.DataFrame:
        """Transform input data using fitted processor.
        
        Args:
            X: Input features dataframe.
            
        Returns:
            Transformed features dataframe.
            
        Raises:
            ValueError: If processor is not fitted.
        """
        # ✅ Validate inputs
        if not self.is_fitted_:
            raise ValueError("DataProcessor must be fitted before transforming")
        
        X = self._validate_input(X)
        
        # 🔄 Apply transformations
        X_transformed = X.copy()
        
        # Step 1: Drop columns that were dropped during fitting
        X_transformed = X_transformed.drop(columns=self.dropped_columns_, errors='ignore')
        
        # Step 2: Apply categorical encoders
        for column, encoder in self.encoders_.items():
            if column in X_transformed.columns:
                # Handle unseen categories
                X_transformed[column] = X_transformed[column].fillna('unknown')
                
                # For label encoders, handle unseen labels
                if hasattr(encoder, 'classes_'):
                    unknown_mask = ~X_transformed[column].isin(encoder.classes_)
                    if unknown_mask.any():
                        X_transformed.loc[unknown_mask, column] = encoder.classes_[0]
                
                X_transformed[column] = encoder.transform(X_transformed[column])
        
        # Step 3: Apply numerical scalers
        for column, scaler in self.scalers_.items():
            if column in X_transformed.columns:
                X_transformed[column] = scaler.transform(X_transformed[[column]])
        
        # Step 4: Ensure final columns match fitted features
        missing_cols = set(self.feature_names_) - set(X_transformed.columns)
        for col in missing_cols:
            X_transformed[col] = 0  # Add missing columns with default value
        
        X_transformed = X_transformed[self.feature_names_]
        
        # 📊 Return transformed data
        return X_transformed
    
    def fit_transform(self, X: pd.DataFrame, y: pd.Series = None) -> pd.DataFrame:
        """Fit processor and transform data in one step.
        
        Args:
            X: Input features dataframe.
            y: Target values (optional).
            
        Returns:
            Transformed features dataframe.
        """
        return self.fit(X, y).transform(X)
    
    def _validate_input(self, X: pd.DataFrame) -> pd.DataFrame:
        """Validate input dataframe.
        
        Args:
            X: Input dataframe to validate.
            
        Returns:
            Validated dataframe.
            
        Raises:
            ValueError: If input is invalid.
        """
        if X is None:
            raise ValueError("X cannot be None")
        
        if not isinstance(X, pd.DataFrame):
            raise ValueError("X must be a pandas DataFrame")
        
        if len(X) == 0:
            raise ValueError("X cannot be empty")
        
        return X
    
    def _fit_handle_missing(self, X: pd.DataFrame) -> pd.DataFrame:
        """Handle missing values during fitting.
        
        Args:
            X: Input dataframe.
            
        Returns:
            Dataframe with missing values handled.
        """
        # Calculate missing value statistics
        missing_stats = X.isnull().sum() / len(X)
        
        # Drop columns with too many missing values
        cols_to_drop = missing_stats[missing_stats > self.missing_threshold].index.tolist()
        self.dropped_columns_.extend(cols_to_drop)
        
        X_processed = X.drop(columns=cols_to_drop)
        
        # Store fill values for remaining columns
        for column in X_processed.columns:
            if X_processed[column].dtype in ['object', 'category']:
                fill_value = X_processed[column].mode().iloc[0] if not X_processed[column].mode().empty else 'unknown'
            else:
                fill_value = X_processed[column].median()
            
            self.feature_stats_[f'{column}_fill_value'] = fill_value
        
        logger.info(f"Dropped {len(cols_to_drop)} columns due to missing values > {self.missing_threshold}")
        
        return X_processed
    
    def _fit_encode_categorical(self, X: pd.DataFrame) -> pd.DataFrame:
        """Fit categorical encoders.
        
        Args:
            X: Input dataframe.
            
        Returns:
            Dataframe with categorical features prepared for encoding.
        """
        categorical_cols = X.select_dtypes(include=['object', 'category']).columns
        
        for column in categorical_cols:
            # Fill missing values first
            fill_value = self.feature_stats_.get(f'{column}_fill_value', 'unknown')
            X[column] = X[column].fillna(fill_value)
            
            # Choose encoder based on cardinality
            n_unique = X[column].nunique()
            
            if n_unique <= 10:  # Use one-hot encoding for low cardinality
                encoder = OneHotEncoder(drop='first', sparse_output=False, handle_unknown='ignore')
                # Fit encoder
                encoder.fit(X[[column]])
                self.encoders_[column] = encoder
            else:  # Use label encoding for high cardinality
                encoder = LabelEncoder()
                encoder.fit(X[column])
                self.encoders_[column] = encoder
        
        logger.info(f"Fitted encoders for {len(categorical_cols)} categorical columns")
        
        return X
    
    def _fit_scale_numerical(self, X: pd.DataFrame) -> pd.DataFrame:
        """Fit numerical feature scalers.
        
        Args:
            X: Input dataframe.
            
        Returns:
            Dataframe with numerical features prepared for scaling.
        """
        numerical_cols = X.select_dtypes(include=[np.number]).columns
        
        for column in numerical_cols:
            # Fill missing values first
            fill_value = self.feature_stats_.get(f'{column}_fill_value', X[column].median())
            X[column] = X[column].fillna(fill_value)
            
            # Fit scaler
            scaler = StandardScaler()
            scaler.fit(X[[column]])
            self.scalers_[column] = scaler
        
        logger.info(f"Fitted scalers for {len(numerical_cols)} numerical columns")
        
        return X
    
    def _fit_feature_selection(self, X: pd.DataFrame, y: pd.Series) -> pd.DataFrame:
        """Fit feature selection based on target variable.
        
        Args:
            X: Input features.
            y: Target variable.
            
        Returns:
            Dataframe with feature selection prepared.
        """
        # This is a placeholder for feature selection logic
        # In practice, you might use SelectKBest, mutual information, etc.
        logger.info("Feature selection fitting completed")
        return X
    
    def _fit_remove_correlated(self, X: pd.DataFrame) -> pd.DataFrame:
        """Remove highly correlated features.
        
        Args:
            X: Input dataframe.
            
        Returns:
            Dataframe with correlated features identified for removal.
        """
        # Calculate correlation matrix for numerical features only
        numerical_cols = X.select_dtypes(include=[np.number]).columns
        
        if len(numerical_cols) > 1:
            corr_matrix = X[numerical_cols].corr().abs()
            
            # Find highly correlated feature pairs
            high_corr_pairs = []
            for i in range(len(corr_matrix.columns)):
                for j in range(i+1, len(corr_matrix.columns)):
                    if corr_matrix.iloc[i, j] > self.correlation_threshold:
                        col1, col2 = corr_matrix.columns[i], corr_matrix.columns[j]
                        high_corr_pairs.append((col1, col2, corr_matrix.iloc[i, j]))
                        # Keep the first feature, drop the second
                        if col2 not in self.dropped_columns_:
                            self.dropped_columns_.append(col2)
            
            logger.info(f"Identified {len(high_corr_pairs)} highly correlated feature pairs")
        
        return X
    
    def get_feature_importance_report(self) -> Dict[str, Any]:
        """Generate feature importance and processing report.
        
        Returns:
            Dictionary containing processing statistics and feature information.
        """
        if not self.is_fitted_:
            raise ValueError("DataProcessor must be fitted to generate report")
        
        report = {
            'total_features_processed': len(self.feature_names_),
            'features_dropped': len(self.dropped_columns_),
            'dropped_column_names': self.dropped_columns_,
            'final_feature_names': self.feature_names_,
            'categorical_encoders': len(self.encoders_),
            'numerical_scalers': len(self.scalers_),
            'processing_parameters': {
                'missing_threshold': self.missing_threshold,
                'correlation_threshold': self.correlation_threshold,
                'scale_features': self.scale_features,
                'encode_categorical': self.encode_categorical
            }
        }
        
        return report

# ----------------------------------------
# Step 4 – Data Loading Utilities
# ----------------------------------------

def load_data(file_path: Union[str, Path], **kwargs) -> pd.DataFrame:
    """Load data from various file formats.
    
    Args:
        file_path: Path to data file.
        **kwargs: Additional arguments passed to pandas loading function.
        
    Returns:
        Loaded dataframe.
        
    Raises:
        ValueError: If file format is not supported.
        FileNotFoundError: If file does not exist.
    """
    # ✅ Validate file path
    file_path = Path(file_path)
    
    if not file_path.exists():
        raise FileNotFoundError(f"File not found: {file_path}")
    
    file_extension = file_path.suffix.lower()
    
    if file_extension not in SUPPORTED_FORMATS:
        raise ValueError(f"Unsupported file format: {file_extension}")
    
    # 🔄 Load data based on format
    logger.info(f"Loading data from {file_path}")
    
    if file_extension == '.csv':
        df = pd.read_csv(file_path, encoding=DEFAULT_ENCODING, **kwargs)
    elif file_extension == '.parquet':
        df = pd.read_parquet(file_path, **kwargs)
    elif file_extension == '.json':
        df = pd.read_json(file_path, **kwargs)
    elif file_extension in ['.excel', '.xlsx', '.xls']:
        df = pd.read_excel(file_path, **kwargs)
    else:
        raise ValueError(f"Unsupported format: {file_extension}")
    
    # 📊 Log loading results
    logger.info(f"Loaded data: {df.shape[0]} rows, {df.shape[1]} columns")
    
    return df

def save_processed_data(df: pd.DataFrame, file_path: Union[str, Path], format: str = 'csv') -> None:
    """Save processed data to file.
    
    Args:
        df: Dataframe to save.
        file_path: Output file path.
        format: Output format ('csv', 'parquet', 'json').
        
    Raises:
        ValueError: If format is not supported.
    """
    # ✅ Validate inputs
    file_path = Path(file_path)
    file_path.parent.mkdir(parents=True, exist_ok=True)
    
    # 🔄 Save data
    logger.info(f"Saving processed data to {file_path}")
    
    if format == 'csv':
        df.to_csv(file_path, index=False)
    elif format == 'parquet':
        df.to_parquet(file_path, index=False)
    elif format == 'json':
        df.to_json(file_path, orient='records', indent=2)
    else:
        raise ValueError(f"Unsupported format: {format}")
    
    # 📊 Log completion
    logger.info(f"Data saved successfully: {df.shape[0]} rows, {df.shape[1]} columns")

# ----------------------------------------
# Step 5 – Data Quality Checks
# ----------------------------------------

def generate_data_quality_report(df: pd.DataFrame) -> Dict[str, Any]:
    """Generate comprehensive data quality report.
    
    Args:
        df: Input dataframe to analyze.
        
    Returns:
        Dictionary containing data quality metrics.
    """
    # ✅ Validate input
    if df is None or len(df) == 0:
        raise ValueError("DataFrame cannot be None or empty")
    
    # 🔄 Calculate quality metrics
    report = {
        'basic_info': {
            'n_rows': len(df),
            'n_columns': len(df.columns),
            'memory_usage_mb': df.memory_usage(deep=True).sum() / 1024**2
        },
        'missing_values': {
            'total_missing': df.isnull().sum().sum(),
            'missing_percentage': (df.isnull().sum().sum() / (len(df) * len(df.columns))) * 100,
            'columns_with_missing': df.columns[df.isnull().any()].tolist(),
            'missing_by_column': df.isnull().sum().to_dict()
        },
        'data_types': {
            'numerical_columns': df.select_dtypes(include=[np.number]).columns.tolist(),
            'categorical_columns': df.select_dtypes(include=['object', 'category']).columns.tolist(),
            'datetime_columns': df.select_dtypes(include=['datetime64']).columns.tolist()
        },
        'duplicates': {
            'n_duplicates': df.duplicated().sum(),
            'duplicate_percentage': (df.duplicated().sum() / len(df)) * 100
        }
    }
    
    # Add numerical column statistics
    numerical_cols = df.select_dtypes(include=[np.number]).columns
    if len(numerical_cols) > 0:
        report['numerical_stats'] = df[numerical_cols].describe().to_dict()
    
    # 📊 Return report
    return report

# ----------------------------------------
# Step 6 – Module Execution
# ----------------------------------------

if __name__ == "__main__":
    # Example usage and testing
    logger.info("Running data processor example...")
    
    # Generate sample data
    np.random.seed(DEFAULT_RANDOM_STATE)
    
    sample_data = pd.DataFrame({
        'numeric_1': np.random.randn(1000),
        'numeric_2': np.random.randn(1000) * 10 + 5,
        'categorical_1': np.random.choice(['A', 'B', 'C'], 1000),
        'categorical_2': np.random.choice(['X', 'Y', 'Z', 'W'], 1000),
        'target': np.random.randint(0, 2, 1000)
    })
    
    # Add some missing values
    sample_data.loc[np.random.choice(sample_data.index, 50), 'numeric_1'] = np.nan
    sample_data.loc[np.random.choice(sample_data.index, 30), 'categorical_1'] = np.nan
    
    # Split features and target
    X = sample_data.drop('target', axis=1)
    y = sample_data['target']
    
    # Split train/test
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=DEFAULT_RANDOM_STATE
    )
    
    # Process data
    processor = DataProcessor()
    X_train_processed = processor.fit_transform(X_train, y_train)
    X_test_processed = processor.transform(X_test)
    
    # Generate reports
    quality_report = generate_data_quality_report(X)
    processing_report = processor.get_feature_importance_report()
    
    # Display results
    print("\n" + "="*60)
    print("DATA PROCESSING EXAMPLE RESULTS")
    print("="*60)
    print(f"Original shape: {X.shape}")
    print(f"Processed train shape: {X_train_processed.shape}")
    print(f"Processed test shape: {X_test_processed.shape}")
    print(f"Features processed: {processing_report['total_features_processed']}")
    print(f"Features dropped: {processing_report['features_dropped']}")
    
    logger.info("Data processor example completed successfully")