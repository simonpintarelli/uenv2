#include <string>

#include <uenv/env.h>

namespace uenv {

uenv_description::uenv_description(std::string file) : value_(std::move(file)) {
}

uenv_description::uenv_description(uenv_label label)
    : value_(std::move(label)) {
}

std::optional<uenv_label> uenv_description::label() const {
    if (!std::holds_alternative<uenv_label>(value_)) {
        return std::nullopt;
    }
    return std::get<uenv_label>(value_);
}

std::optional<std::string> uenv_description::filename() const {
    if (!std::holds_alternative<std::string>(value_)) {
        return std::nullopt;
    }
    return std::get<std::string>(value_);
}

} // namespace uenv
