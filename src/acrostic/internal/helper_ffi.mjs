import { exec } from 'child_process';

export function do_cmd(command) {
  exec(command)
}