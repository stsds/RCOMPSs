#include "core/Serialization.hpp"

#include <cstdint>
#include <fstream>
#include <stdexcept>
#include <string>

namespace RCOMPSs {
namespace core {

namespace {

constexpr std::uint32_t kMagic = 0x52535343;  // "RCSS"
// v1: lists had no names attribute on disk. v2: VECSXP may include names (same length as list).
constexpr std::uint32_t kVersion = 2;
constexpr std::uint32_t kMinReadVersion = 1;

enum class ValueType : std::uint32_t {
  kNil = 0,
  kLogical = 1,
  kInteger = 2,
  kReal = 3,
  kString = 4,
  kList = 5
};

void writeBytes(std::ofstream& out, const void* data, std::size_t size) {
  out.write(reinterpret_cast<const char*>(data), static_cast<std::streamsize>(size));
  if (!out) {
    throw std::runtime_error("Serialization write failed");
  }
}

void readBytes(std::ifstream& in, void* data, std::size_t size) {
  in.read(reinterpret_cast<char*>(data), static_cast<std::streamsize>(size));
  if (!in) {
    throw std::runtime_error("Serialization read failed");
  }
}

void writeU32(std::ofstream& out, std::uint32_t value) {
  writeBytes(out, &value, sizeof(value));
}

std::uint32_t readU32(std::ifstream& in) {
  std::uint32_t value = 0;
  readBytes(in, &value, sizeof(value));
  return value;
}

void writeI32(std::ofstream& out, std::int32_t value) {
  writeBytes(out, &value, sizeof(value));
}

std::int32_t readI32(std::ifstream& in) {
  std::int32_t value = 0;
  readBytes(in, &value, sizeof(value));
  return value;
}

void writeString(std::ofstream& out, SEXP str) {
  if (str == NA_STRING) {
    writeI32(out, -1);
    return;
  }
  const char* data = CHAR(str);
  std::int32_t len = static_cast<std::int32_t>(LENGTH(str));
  if (len < 0) {
    throw std::runtime_error("Invalid string length");
  }
  writeI32(out, len);
  if (len > 0) {
    writeBytes(out, data, static_cast<std::size_t>(len));
  }
}

SEXP readString(std::ifstream& in, int& protect_count) {
  std::int32_t len = readI32(in);
  if (len == -1) {
    return NA_STRING;
  }
  if (len < 0) {
    throw std::runtime_error("Invalid serialized string length");
  }
  std::string buffer(static_cast<std::size_t>(len), '\0');
  if (len > 0) {
    readBytes(in, &buffer[0], static_cast<std::size_t>(len));
  }
  SEXP str = Rf_mkCharLen(buffer.data(), len);
  return str;
}

void writeSEXP(std::ofstream& out, SEXP object, std::uint32_t format_version);
SEXP readSEXP(std::ifstream& in, int& protect_count, std::uint32_t format_version);

void writeSEXP(std::ofstream& out, SEXP object, std::uint32_t format_version) {
  if (object == R_NilValue) {
    writeU32(out, static_cast<std::uint32_t>(ValueType::kNil));
    return;
  }

  switch (TYPEOF(object)) {
    case LGLSXP: {
      writeU32(out, static_cast<std::uint32_t>(ValueType::kLogical));
      R_xlen_t len = XLENGTH(object);
      writeU32(out, static_cast<std::uint32_t>(len));
      int* data = LOGICAL(object);
      for (R_xlen_t i = 0; i < len; ++i) {
        writeI32(out, static_cast<std::int32_t>(data[i]));
      }
      return;
    }
    case INTSXP: {
      writeU32(out, static_cast<std::uint32_t>(ValueType::kInteger));
      R_xlen_t len = XLENGTH(object);
      writeU32(out, static_cast<std::uint32_t>(len));
      int* data = INTEGER(object);
      for (R_xlen_t i = 0; i < len; ++i) {
        writeI32(out, static_cast<std::int32_t>(data[i]));
      }
      return;
    }
    case REALSXP: {
      writeU32(out, static_cast<std::uint32_t>(ValueType::kReal));
      R_xlen_t len = XLENGTH(object);
      writeU32(out, static_cast<std::uint32_t>(len));
      double* data = REAL(object);
      writeBytes(out, data, static_cast<std::size_t>(len) * sizeof(double));
      return;
    }
    case STRSXP: {
      writeU32(out, static_cast<std::uint32_t>(ValueType::kString));
      R_xlen_t len = XLENGTH(object);
      writeU32(out, static_cast<std::uint32_t>(len));
      for (R_xlen_t i = 0; i < len; ++i) {
        SEXP str = STRING_ELT(object, i);
        writeString(out, str);
      }
      return;
    }
    case VECSXP: {
      writeU32(out, static_cast<std::uint32_t>(ValueType::kList));
      R_xlen_t len = XLENGTH(object);
      writeU32(out, static_cast<std::uint32_t>(len));
      if (format_version >= 2) {
        SEXP nms = Rf_getAttrib(object, R_NamesSymbol);
        const int has_names =
            (nms != R_NilValue && TYPEOF(nms) == STRSXP && XLENGTH(nms) == len) ? 1 : 0;
        writeU32(out, static_cast<std::uint32_t>(has_names));
        if (has_names) {
          for (R_xlen_t i = 0; i < len; ++i) {
            writeString(out, STRING_ELT(nms, i));
          }
        }
      }
      for (R_xlen_t i = 0; i < len; ++i) {
        writeSEXP(out, VECTOR_ELT(object, i), format_version);
      }
      return;
    }
    default:
      break;
  }

  throw std::runtime_error("Unsupported SEXP type for C++ serialization");
}

SEXP readSEXP(std::ifstream& in, int& protect_count, std::uint32_t format_version) {
  auto type = static_cast<ValueType>(readU32(in));
  switch (type) {
    case ValueType::kNil:
      return R_NilValue;
    case ValueType::kLogical: {
      std::uint32_t len = readU32(in);
      SEXP vec = Rf_allocVector(LGLSXP, len);
      PROTECT(vec);
      ++protect_count;
      int* data = LOGICAL(vec);
      for (std::uint32_t i = 0; i < len; ++i) {
        data[i] = static_cast<int>(readI32(in));
      }
      return vec;
    }
    case ValueType::kInteger: {
      std::uint32_t len = readU32(in);
      SEXP vec = Rf_allocVector(INTSXP, len);
      PROTECT(vec);
      ++protect_count;
      int* data = INTEGER(vec);
      for (std::uint32_t i = 0; i < len; ++i) {
        data[i] = static_cast<int>(readI32(in));
      }
      return vec;
    }
    case ValueType::kReal: {
      std::uint32_t len = readU32(in);
      SEXP vec = Rf_allocVector(REALSXP, len);
      PROTECT(vec);
      ++protect_count;
      double* data = REAL(vec);
      readBytes(in, data, static_cast<std::size_t>(len) * sizeof(double));
      return vec;
    }
    case ValueType::kString: {
      std::uint32_t len = readU32(in);
      SEXP vec = Rf_allocVector(STRSXP, len);
      PROTECT(vec);
      ++protect_count;
      for (std::uint32_t i = 0; i < len; ++i) {
        SEXP str = readString(in, protect_count);
        SET_STRING_ELT(vec, i, str);
      }
      return vec;
    }
    case ValueType::kList: {
      std::uint32_t len = readU32(in);
      SEXP list = Rf_allocVector(VECSXP, len);
      PROTECT(list);
      ++protect_count;
      if (format_version >= 2) {
        std::uint32_t has_names = readU32(in);
        if (has_names > 1) {
          throw std::runtime_error("Invalid list name flag in serialized data");
        }
        if (has_names != 0) {
          SEXP nms = Rf_allocVector(STRSXP, len);
          PROTECT(nms);
          ++protect_count;
          for (std::uint32_t i = 0; i < len; ++i) {
            SEXP str = readString(in, protect_count);
            SET_STRING_ELT(nms, i, str);
          }
          Rf_setAttrib(list, R_NamesSymbol, nms);
          UNPROTECT(1);
          --protect_count;
        }
      }
      for (std::uint32_t i = 0; i < len; ++i) {
        SEXP element = readSEXP(in, protect_count, format_version);
        SET_VECTOR_ELT(list, i, element);
      }
      return list;
    }
    default:
      break;
  }

  throw std::runtime_error("Unsupported serialized value type");
}

}  // namespace

void Serialization::serializeSEXP(SEXP object, const std::string& filepath) {
  std::ofstream out(filepath, std::ios::binary);
  if (!out) {
    throw std::runtime_error("Failed to open file for serialization: " + filepath);
  }
  writeU32(out, kMagic);
  writeU32(out, kVersion);
  writeSEXP(out, object, kVersion);
}

SEXP Serialization::unserializeSEXP(const std::string& filepath) {
  std::ifstream in(filepath, std::ios::binary);
  if (!in) {
    throw std::runtime_error("Failed to open file for unserialization: " + filepath);
  }
  std::uint32_t magic = readU32(in);
  if (magic != kMagic) {
    throw std::runtime_error("Invalid serialization magic header");
  }
  std::uint32_t version = readU32(in);
  if (version < kMinReadVersion || version > kVersion) {
    throw std::runtime_error("Unsupported serialization version");
  }
  int protect_count = 0;
  SEXP result = readSEXP(in, protect_count, version);
  UNPROTECT(protect_count);
  return result;
}

}  // namespace core
}  // namespace RCOMPSs

