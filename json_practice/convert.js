// this script was used to clean up data from original precise_download_events.json into a data safe, sharable state.
// it won't really do anything now...

import fs from 'node:fs/promises';

let jsonData;

try {
  const data = await fs.readFile('./precise_download_events.json', { encoding: 'utf8' });
  jsonData = JSON.parse(data);
} catch (err) {
  console.error(err);
}

  const newObject = [];
  const usersHash = {};
  const filesHash = {};
  let userCount = 0;
  let fileCount = 1;
  const newValidFiles = ['file_53', 'file_108']

  for (const key of jsonData) {
    // add new files to file hash
    if (!Object.keys(filesHash).includes(key.filename)) {
      filesHash[key.filename] = key.filename === null ? null : `file_${fileCount}`;
      fileCount += 1;
    };
    
    // add new users to user hash
    if (!Object.keys(usersHash).includes(key.name)) {
      usersHash[key.name] = {
        new_name: `user ${userCount}`,
        new_email: `user${userCount}@email.com`,
        new_id: +`${userCount + 1}` // + converts string to int here
        };

        userCount += 1;
    };


    const convertObject = {
      name: usersHash[key.name]["new_name"],
      email: usersHash[key.name]["new_email"],
      user_id: usersHash[key.name]["new_id"],
      filename: filesHash[key.filename],
      access_date: key.access_date,
    };
    newObject.push(convertObject);
  }

  try {
    await fs.writeFile('./precise_download_events_new.json', JSON.stringify(newObject, null, 4));
  } catch(err) {
    console.log(err);
  };
