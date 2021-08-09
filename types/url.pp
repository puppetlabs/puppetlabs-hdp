# HDP::Url is a metatype that supports both single and multiple urls
#
# @summary HDP::Url is a metatype that supports both single and multiple urls
type HDP::Url = Variant[Array[Stdlib::HTTPUrl], Stdlib::HTTPUrl]
