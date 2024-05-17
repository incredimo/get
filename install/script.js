// script.js

document.addEventListener("DOMContentLoaded", function () {
    const fileList = document.getElementById('fileList');
    const files = ['script1.sh', 'script2.ps1', 'script3.py']; // List your files here
    files.forEach(file => {
      const listItem = document.createElement('li');
      listItem.textContent = file;
      fileList.appendChild(listItem);
    });
  });
  