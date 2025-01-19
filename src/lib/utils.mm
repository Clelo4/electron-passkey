#include "utils.h"
#include <Foundation/Foundation.h>
#include <Foundation/NSData.h>

NSString *ToNSString(const std::string &str) {
  if (str.empty()) return @"";
  return [NSString stringWithUTF8String:str.c_str()];
}

NSData *ToNSData(const std::vector<uint8_t> &data) {
  if (data.empty()) {
    return [NSData data];
  }
  return [NSData dataWithBytes:data.data() length:data.size()];
}
