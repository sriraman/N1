import fs from 'fs-plus'
import path from 'path'

var here = path.resolve(__dirname)

const DEFAULT_CONFIG = path.join(here, "default_test_config")
export const CONFIG_DIR_PATH = path.join(here, ".integration-test-config")
export const FAKE_DATA_PATH = path.join(here, "test_account_data")

export function setupDefaultConfig() {
  if (fs.existsSync(CONFIG_DIR_PATH)) fs.removeSync(CONFIG_DIR_PATH);
  fs.copySync(DEFAULT_CONFIG, CONFIG_DIR_PATH)
}

export function clearConfig() {
  if (fs.existsSync(CONFIG_DIR_PATH)) fs.removeSync(CONFIG_DIR_PATH);
}
