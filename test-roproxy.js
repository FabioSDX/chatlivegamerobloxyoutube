const userId = '9820246327';
const url = `https://thumbnails.roproxy.com/v1/users/avatar-3d?userId=${userId}`;
fetch(url)
    .then(r => r.json())
    .then(data => console.log(JSON.stringify(data, null, 2)))
    .catch(e => console.error(e.message));
