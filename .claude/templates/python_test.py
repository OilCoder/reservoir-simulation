"""Tests for [module_name] functionality."""

import pytest
import numpy as np
from unittest.mock import Mock, patch

# Import module to test
from src.module_name import (
    main_function,
    helper_function,
    CustomClass
)

# ----------------------------------------
# Step 1 – Test Fixtures and Setup
# ----------------------------------------

@pytest.fixture
def sample_data():
    """Provide sample data for tests."""
    return {
        'input1': np.array([1, 2, 3, 4, 5]),
        'input2': {'key': 'value'},
        'expected': 15
    }

@pytest.fixture
def mock_external_service():
    """Mock external service for isolated testing."""
    with patch('src.module_name.external_api') as mock_api:
        mock_api.fetch_data.return_value = {'status': 'success'}
        yield mock_api

# ----------------------------------------
# Step 2 – Unit Tests for Functions
# ----------------------------------------

class TestMainFunction:
    """Test cases for main_function."""
    
    def test_normal_operation(self, sample_data):
        """Test function with normal valid inputs."""
        # ✅ Arrange
        input_val = sample_data['input1']
        expected = sample_data['expected']
        
        # 🔄 Act
        result = main_function(input_val)
        
        # 📊 Assert
        assert result == expected
        assert isinstance(result, (int, float))
    
    def test_empty_input_raises_error(self):
        """Test function raises ValueError for empty input."""
        # ✅ Arrange
        empty_input = []
        
        # 🔄 Act & Assert
        with pytest.raises(ValueError, match="cannot be empty"):
            main_function(empty_input)
    
    def test_none_input_raises_error(self):
        """Test function raises ValueError for None input."""
        with pytest.raises(ValueError, match="cannot be None"):
            main_function(None)
    
    @pytest.mark.parametrize("input_val,expected", [
        ([1], 1),
        ([1, 2], 3),
        ([1, 2, 3], 6),
        ([-1, -2, -3], -6),
    ])
    def test_various_inputs(self, input_val, expected):
        """Test function with various input sizes."""
        result = main_function(input_val)
        assert result == expected

# ----------------------------------------
# Step 3 – Integration Tests
# ----------------------------------------

@pytest.mark.integration
class TestIntegration:
    """Integration tests for module components."""
    
    def test_full_workflow(self, sample_data, mock_external_service):
        """Test complete workflow from input to output."""
        # ✅ Arrange
        input_data = sample_data['input1']
        
        # 🔄 Act
        intermediate = helper_function(input_data)
        final_result = main_function(intermediate)
        
        # 📊 Assert
        assert mock_external_service.fetch_data.called
        assert final_result is not None
        assert isinstance(final_result, (int, float))

# ----------------------------------------
# Step 4 – Performance Tests
# ----------------------------------------

@pytest.mark.slow
class TestPerformance:
    """Performance tests for critical functions."""
    
    def test_large_dataset_performance(self):
        """Test function performance with large dataset."""
        # ✅ Arrange
        large_data = np.random.rand(1_000_000)
        
        # 🔄 Act
        import time
        start_time = time.time()
        result = main_function(large_data)
        elapsed_time = time.time() - start_time
        
        # 📊 Assert
        assert result is not None
        assert elapsed_time < 1.0  # Should complete in under 1 second

# ----------------------------------------
# Step 5 – Edge Cases and Error Handling
# ----------------------------------------

class TestEdgeCases:
    """Test edge cases and error conditions."""
    
    def test_boundary_conditions(self):
        """Test function at boundary conditions."""
        # Test with maximum allowed value
        max_input = [float('inf')]
        with pytest.raises(ValueError, match="Input out of range"):
            main_function(max_input)
    
    def test_type_validation(self):
        """Test function validates input types."""
        # Test with wrong type
        wrong_type = "not a list"
        with pytest.raises(TypeError, match="Expected list or array"):
            main_function(wrong_type)