use std::process::Command;

fn main() {
    let res = Command::new("kubectl")
               .arg("get")
               .arg("pods")
               .output()
               .expect("failed to execute process");
    println!("{}", String::from_utf8_lossy(&res.stdout));
    println!("{}", String::from_utf8_lossy(&res.stderr));
    println!("Hello, world!");
}
