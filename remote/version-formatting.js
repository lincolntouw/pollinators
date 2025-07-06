export default function(v) {
  v ||= 0;
  return `${Math.floor(v / 1000)}f${(v - Math.floor(v / 1000)).toString(32)}`;
}
