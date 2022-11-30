
const express = require('express')
const router = express.Router()
const searchController = require('../controllers/searchController')

router.route('/')
    .get(searchController.handleQuery)

module.exports = router