const express = require('express');
const { Pool } = require('pg');

const app = express();
const PORT = process.env.PORT || 5000;

const pool = new Pool({
  host: process.env.DB_HOST || 'db',
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

app.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW() AS time');
    res.send(
      `<h1>DevOps Assignment - Node.js App</h1>` +
      `<p>Served via Nginx reverse proxy.</p>` +
      `<p>Database connected. Current DB time: ${result.rows[0].time}</p>`
    );
  } catch (err) {
    res.status(500).send(
      `<h1>DevOps Assignment - Node.js App</h1>` +
      `<p>App is running, but DB connection failed: ${err.message}</p>`
    );
  }
});

// health endpoint for the Task 3 script to check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`App listening on port ${PORT}`);
});
