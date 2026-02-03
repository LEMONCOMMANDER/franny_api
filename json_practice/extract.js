import fs from 'node:fs/promises';

let jsonData
try {
  const data = await fs.readFile('./precise_download_events.json', { encoding: 'utf8' });
  jsonData = JSON.parse(data);
} catch (err) {
  console.error(err);
}

  const usersHash = {};
  const fileViews = {};
  const validFiles = ["file_53", "file_108"]

  // creates unique array of names and emails
  for (const key of jsonData) {
    if (!usersHash[key.name]) {
      usersHash[key.name] = key.email;
    }

    //TODO: add time stamp instead or in addition to count
    if (validFiles.includes(key.file_name)) {
      // update existing
      if (!fileViews[key.name]) {
        fileViews[key.name] = {[key.file_name]: [key.access_date]};
      }
      const file = fileViews[key.name]


      if (fileViews[key.name] && fileViews[key.name][key.file_name]) {
        fileViews[key.name][key.file_name].push(key.access_date);
      // add other file  
      } else if (Object.hasOwn(fileViews, key.name) && !fileViews[key.name][key.file_name]) {
        fileViews[key.name][key.file_name] = [key.access_date];
      // add for the first time
      } else {
        fileViews[key.name] = {[key.file_name]: [key.access_date]};
      }
    }
  }

  console.log(fileViews);


// generate array of all unique names and emails 
// there are 2 file names passed: 2023-Q3 - 941 | Mossberg Serialization Information
//    find each user that accessed these files - provide a timestamp for each visit 