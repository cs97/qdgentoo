use std::str;
use std::fs;
use std::process::Command;

fn main() {

  //MHz
  // /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq
  let mut max_freq = 0;
  let mut core_num = 0;
  let mut cur_freq;

  for n in 0..=7 {
    cur_freq = return_cpu_freq(n);

    if cur_freq > max_freq {
      max_freq = cur_freq;
      core_num = n;  
    }
  }

  let cpu_string = format!("{}", max_freq);
  let cpu_mhz = cpu_string.split_at(cpu_string.len() - 3);
  let cpu = format!("CPU{}:[{}MHz]", core_num.to_string(), cpu_mhz.0);


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

fn return_cpu_freq(core: usize) -> usize {
  let core = "/sys/devices/system/cpu/cpu".to_string() + &core.to_string() + "/cpufreq/scaling_cur_freq";
  let core_freq = return_string(core).to_string();
  let u64freq = core_freq.parse::<usize>().unwrap();
  return u64freq
}

fn return_string(filename: String) -> String {
  let mut s = fs::read_to_string(filename).expect("File not found");
  s.pop();
  return s
}
