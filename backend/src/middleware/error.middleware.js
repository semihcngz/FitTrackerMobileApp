export const errorHandler = (err, req, res, next) => {
    console.error('Error:', err);
  
    // PostgreSQL hatası
    if (err.code === '23505') {
      return res.status(409).json({
        error: 'Duplicate entry',
        message: 'This record already exists'
      });
    }
  
    if (err.code === '23503') {
      return res.status(400).json({
        error: 'Foreign key violation',
        message: 'Referenced record does not exist'
      });
    }
  
    // Varsayılan hata
    res.status(err.status || 500).json({
      error: err.message || 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? err.stack : 'Something went wrong'
    });
  };
  
  // Async fonksiyonları wrap etmek için
  export const asyncHandler = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };