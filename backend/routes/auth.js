const express = require('express')

const authController = require('../controller/auth')

const router = express.Router()

router.get('/posts')

module.exports = router;