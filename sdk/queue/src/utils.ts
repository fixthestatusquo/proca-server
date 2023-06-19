export const pause = (time?: number): Promise<any> => {
  const min = (time && time > 2) ? time / 2 : 1;
  const max = time ? time * 2 : 2; // wait between min time/2 and time*2
  time = Math.floor(Math.random() * (max - min + 1) + min) * 1000;
  console.log("wait", time);
  return new Promise(resolve => setTimeout(() => resolve(time), time));
};
