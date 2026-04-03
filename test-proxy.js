const userId = '9820246327';
const url = `https://ro-render-glb.glitch.me/avatar-3d/${userId}`;
fetch(url)
    .then(r => {
        console.log("Status:", r.status);
        console.log("Headers:", JSON.stringify([...r.headers], null, 2));
    })
    .catch(e => console.error(e));
