const userId = '9820246327';
const url = `https://avatar-glb.skid9k.xyz/${userId}`; // common pattern for this proxy
fetch(url, { method: 'HEAD' })
    .then(r => {
        console.log("Status:", r.status);
        console.log("OK:", r.ok);
    })
    .catch(e => console.error("Error:", e.message));
