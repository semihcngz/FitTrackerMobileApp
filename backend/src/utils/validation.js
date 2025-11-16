export const validateEmail = (email) => {
  return email && email.includes('@') && email.includes('.');
};

  
  export const validatePassword = (password) => {
    return password && password.length >= 6;
  };
  
  export const validateRequired = (fields, data) => {
    const missing = fields.filter(field => !data[field]);
    if (missing.length > 0) {
      throw new Error(`Missing required fields: ${missing.join(', ')}`);
    }
  };