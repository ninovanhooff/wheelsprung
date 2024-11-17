// import {transpile} from 'typescript'

let code: string = `({
  Run: (data: string): string => {
      console.log(data); return Promise.resolve("SUCCESS"); }
  })`;

export function evalDemo(expression: string = code) {
  // let runnable :any = eval(result);
  // runnable.Run("RUN!").then((result:string)=>{tiled.log(result);});
  for (let i = 0; i < 10; i++) {
    let x = i;
    let result = eval(expression.replace("x", x.toString()));
    tiled.log(eval(result))
  }
}