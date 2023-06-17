export const pause = (time? : number): Promise <any>=> {
       
      const min = (!time || time > 19) ? 19: time /2; 
      const max = time || 42; // wait between min and max
      time = Math.floor(Math.random() * (max - min + 1) + min) *1000;
    return new Promise(resolve => setTimeout(() => resolve(time), time));
}


