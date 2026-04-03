const userId = '9820246327';
const url = `https://roblox-api.deno.dev/avatar-3d?userId=${userId}`;
fetch(url)
    .then(r => {
        console.log("Status:", r.status);
        if (r.ok) return r.json();
        throw new Error("Failed");
    })
    .then(data => console.log(JSON.stringify(data, null, 2)))
    .catch(e => console.error(e.message));
