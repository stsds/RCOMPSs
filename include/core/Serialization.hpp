#ifndef RCOMPSs_CORE_SERIALIZATION_HPP
#define RCOMPSs_CORE_SERIALIZATION_HPP

#ifndef R_NO_REMAP
#define R_NO_REMAP
#endif

#include <Rinternals.h>
#include <string>

namespace RCOMPSs {
namespace core {

class Serialization {
public:
  static void serializeSEXP(SEXP object, const std::string& filepath);
  static SEXP unserializeSEXP(const std::string& filepath);
};

}  // namespace core
}  // namespace RCOMPSs

#endif  // RCOMPSs_CORE_SERIALIZATION_HPP