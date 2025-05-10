require('dotenv').config();
const express = require('express');
const { MongoClient, ObjectId } = require('mongodb');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const uri = process.env.MONGO_URI;
const client = new MongoClient(uri);
let db; // variabile globale per il database

async function startServer() {
  try {
    // Connessione singola all'avvio
    await client.connect();
    db = client.db('Progetto');

    // Endpoint per registrazione
    app.post('/register', async (req, res) => {
      const { username, email, password } = req.body;
      const users = db.collection('Users');
      const existingUser = await users.findOne({ $or: [{ username }, { email }] });

      if (existingUser) {
        return res.status(400).json({ error: 'Username o email già registrati' });
      }

      const result = await users.insertOne({
        username,
        email,
        password, // usa bcrypt in produzione
        createdAt: new Date()
      });

      res.status(201).json({ message: 'Utente registrato', userId: result.insertedId });
    });



    // Endpoint login
    app.post('/login', async (req, res) => {
      const { email, password } = req.body;

      try {
        const users = db.collection('Utenti');
        // Cerca l'utente nel database usando l'email e la password
        const user = await users.findOne({ email, password_hash: password });

        if (user) {
          // Aggiungi allenamenti_salvati alla risposta
          res.json({
            success: true,
            user: {
              id: user._id,
              nome: user.nome,
              email: user.email,
              allenamenti_salvati: user.allenamenti_salvati  // Aggiungi i dati degli allenamenti
            }
          });
        } else {
          res.status(401).json({ success: false, error: 'Credenziali non valide' });
        }
      } catch (error) {
        console.error('Errore nel login:', error);
        res.status(500).json({ success: false, error: 'Errore interno del server' });
      }
    });

    



    // Endpoint utente
    app.get('/user/:id', async (req, res) => {
      try {
        const users = db.collection('Users');
        const user = await users.findOne(
          { _id: new ObjectId(req.params.id) },
          { projection: { password: 0 } }
        );

        if (user) {
          res.json(user);
        } else {
          res.status(404).json({ error: 'Utente non trovato' });
        }
      } catch (error) {
        res.status(400).json({ error: 'ID non valido' });
      }
    });

    // Avvia il server
    const PORT = process.env.PORT || 3000;
    app.listen(PORT, () => console.log(`Server in ascolto su http://localhost:${PORT}`));
  } catch (err) {
    console.error('Errore durante l\'avvio del server:', err);
  }
}

startServer();
