const fs = require('fs');
const path = 'c:/Project/getwork 1/getwork/getwork/frontend/mobile/lib/page/topup_form_page.dart';
const lines = fs.readFileSync(path, 'utf8').split(/\r?\n/);
let diff = 0;
for (let i = 0; i < lines.length; i++) {
  const l = lines[i];
  const opens = (l.split('').filter(c => c === '(').length);
  const closes = (l.split('').filter(c => c === ')').length);
  diff += opens - closes;
  if (opens - closes !== 0) console.log(`${i+1}: opens=${opens} closes=${closes} diff=${diff} | ${l}`);
}
console.log('FINAL DIFF='+diff);
