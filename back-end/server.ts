/**
 * @file This is where the back-end source code starts.
 * This file initializes the Express server.
 */

import express from 'express';
import { Request, Response } from 'express';
import path from 'path';

const PORT = 3000;
const app = express();

app.use(express.json());

// Handle front-end (preact-app) pages
app.get('/about', sendIndexHtmlHandler);

// Host the static files inside ../preact-app/dist
// We go two folders up because the compiled (JS) code is in a subfolder
const frontEndFolderPath = path.join(__dirname, '../../preact-app/dist');
app.use(express.static(frontEndFolderPath));

// For every other route, send the index.html file with a 404 status code
app.use((req: Request, res: Response) => {
  res.status(404);
  return sendIndexHtmlHandler(req, res);
});

// Start the Express server
app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});

function sendIndexHtmlHandler(req: Request, res: Response) {
  // We go two folders up because the compiled (JS) code is in a subfolder
  const indexHtmlPath = path.join(__dirname, '../../preact-app/dist/index.html');
  res.sendFile(indexHtmlPath);
}
