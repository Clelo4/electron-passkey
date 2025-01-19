#ifndef UTILS_H
#define UTILS_H

#include <Foundation/Foundation.h>
#include <string>
#include <vector>

NSString* ToNSString(const std::string& str);

NSData* ToNSData(const std::vector<uint8_t>& data);

#endif // UTILS_H
