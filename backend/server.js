const express = require('express')

const app = express()

const authRoutes = require('./routes/auth')

const PORT = 8080

app.use('./auth', authRoutes)

app.listen(PORT, () => {
  console.log(`Server: http://localhost:${PORT}`)
})