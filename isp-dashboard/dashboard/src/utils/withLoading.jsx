import React from 'react';

  const withLoading = (WrappedComponent) => {
    return function WithLoadingComponent({ ...props }) {
      const [isLoading, setIsLoading] = React.useState(true);
      const [error, setError] = React.useState(null);
      const [hasData, setHasData] = React.useState(true);

      const fetchData = async (fetchFunction) => {
        setIsLoading(true);
        setError(null);
        setHasData(true);
        try {
          const result = await fetchFunction();
          // If the fetch function returns a value (e.g., data length), use it to set hasData
          if (typeof result === 'number') {
            setHasData(result > 0);
          }
        } catch (err) {
          setError(err.message || 'An error occurred');
        } finally {
          setIsLoading(false);
        }
      };

      return (
        <div className="container">
          {isLoading ? (
            <div className="loading">Loading...</div>
          ) : error ? (
            <div className="error">Error: {error}</div>
          ) : !hasData ? (
            <div className="no-data">No data available</div>
          ) : (
            <WrappedComponent {...props} fetchData={fetchData} setHasData={setHasData} />
          )}
        </div>
      );
    };
  };

  export default withLoading;