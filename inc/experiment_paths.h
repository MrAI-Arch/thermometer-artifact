#ifndef THERMOMETER_EXPERIMENT_PATHS_H
#define THERMOMETER_EXPERIMENT_PATHS_H
#include <cstdlib>
#include <string>
// Preserve upstream behavior unless explicitly redirected by the experiment.
inline std::string thermometer_data_path(const std::string& suffix = "") {
    const char* value = std::getenv("THERMOMETER_DATA_ROOT");
    std::string root = value && *value ? value : "/mnt/storage/shixins/champsim_pt";
    while (!root.empty() && root.back() == '/') root.pop_back();
    return root + "/" + suffix;
}
#endif
