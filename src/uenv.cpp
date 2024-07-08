// vim: ts=4 sts=4 sw=4 et

#include <CLI/CLI.hpp>
#include <fmt/color.h>
#include <fmt/core.h>

#include "start.h"
#include "uenv.h"

void help() {
    fmt::println("usage main");
}

int main(int argc, char **argv) {
    uenv::global_settings settings;

    CLI::App cli("uenv");
    cli.add_flag("-v,--verbose", settings.verbose, "enable verbose output");

    uenv::start_options start_opt;
    start_opt.add_cli(cli, settings);

    CLI11_PARSE(cli, argc, argv);

    fmt::print(fmt::emphasis::bold | fg(fmt::color::orange), "{}\n", settings);

    switch (settings.mode) {
    case uenv::mode_start:
        uenv::start(start_opt, settings);
        break;
    case uenv::mode_none:
    default:
        help();
    }

    return 0;
}
