const express = require('express');
const cors = require('cors');
const app = express();
const port = 3001;


app.use(cors());

app.get('/', (req, res) => {
    const startTime = Date.now(); // Hora de inicio de la solicitud

    const serverAddress = req.hostname || 'localhost';  
    const responseTime = Date.now() - startTime; 
    const responseTimeSec = (responseTime / 1000).toFixed(3); 
    
    const currentTime = new Date().toISOString(); 

    res.json({
        service:'RENIEC',
        serverAddress: serverAddress,
        timestamp: currentTime,
        latency_ms: responseTime,
        latency_sec: responseTimeSec
    });
});

// Iniciar servidor
app.listen(port, () => {
    console.log(`Servidor escuchando en http://localhost:${port}`);
});
