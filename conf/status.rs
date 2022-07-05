use std::str;
use std::fs;
use std::process::Command;

fn main() {

  //MHz
  // /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq
  let mut cpu_freq = return_string("/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq".to_string());
  cpu_freq.pop();
  cpu_freq.pop();
  cpu_freq.pop();
  let cpu = format!("CPU:[{}MHz]", cpu_freq);


  //BAT
  // /sys/class/power_supply/BAT0/capacity
  let bat_cap = return_string("/sys/class/power_supply/BAT0/capacity".to_string());
  // /sys/class/power_supply/BAT0/status
  let bat_stat = return_string("/sys/class/power_supply/BAT0/status".to_string());
  let bat = format!("BAT:[{}% {}]", bat_cap, bat_stat);
 

  //date
  let output = Command::new("date").args(["+%a %F %H:%M"]).output().expect("failed to execute process");
  let date = format!("{:?}", String::from_utf8_lossy(&output.stdout));
  let date = format!("DATE:[{}]", &date[0..20]);


  //vol
  //let vol = return_vol();
  let cmd = "amixer".to_string();
  let output = Command::new(cmd).output().expect("failed to execute process");
  let vol = str::from_utf8(&output.stdout).unwrap();

  let vol_left = &vol[191..196];
  let vol_rigth = &vol[232..242];
  let vol = format!("VOL: {}{}", vol_left, vol_rigth);


  //status
  let stat = format!("{} {} {} {}", cpu, vol, bat, date);
  println!("{}", stat);

}


fn return_string(filename: String) -> String {
  let mut s = fs::read_to_string(filename).expect("File not found");
  s.pop();
  return s
}
