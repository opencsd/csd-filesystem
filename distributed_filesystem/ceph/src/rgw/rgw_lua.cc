#include <lua.hpp>
#include "services/svc_zone.h"
#include "services/svc_sys_obj.h"
#include "common/dout.h"
#include "rgw_lua_utils.h"
#include "rgw_sal_rados.h"
#include "rgw_lua.h"
#ifdef WITH_RADOSGW_LUA_PACKAGES
#include <filesystem>
#include <boost/process.hpp>
#include "rgw_lua_version.h"
#endif

#define dout_subsys ceph_subsys_rgw

namespace rgw::lua {

context to_context(const std::string& s) 
{
  if (strcasecmp(s.c_str(), "prerequest") == 0) {
    return context::preRequest;
  }
  if (strcasecmp(s.c_str(), "postrequest") == 0) {
    return context::postRequest;
  }
  return context::none;
}

std::string to_string(context ctx) 
{
  switch (ctx) {
    case context::preRequest:
      return "prerequest";
    case context::postRequest:
      return "postrequest";
    case context::none:
      break;
  }
  return "none";
}

bool verify(const std::string& script, std::string& err_msg) 
{
  lua_State *L = luaL_newstate();
  lua_state_guard guard(L);
  open_standard_libs(L);
  try {
    if (luaL_loadstring(L, script.c_str()) != LUA_OK) {
      err_msg.assign(lua_tostring(L, -1));
      return false;
    }
  } catch (const std::runtime_error& e) {
    err_msg = e.what();
    return false;
  }
  err_msg = "";
  return true;
}

std::string script_oid(context ctx, const std::string& tenant) {
  static const std::string SCRIPT_OID_PREFIX("script.");
  return SCRIPT_OID_PREFIX + to_string(ctx) + "." + tenant;
}


int read_script(const DoutPrefixProvider *dpp, rgw::sal::Store* store, const std::string& tenant, optional_yield y, context ctx, std::string& script)
{
  auto lua_script = store->get_lua_script_manager();

  return lua_script->get(dpp, y, script_oid(ctx, tenant), script);
}

int write_script(const DoutPrefixProvider *dpp, rgw::sal::Store* store, const std::string& tenant, optional_yield y, context ctx, const std::string& script)
{
  auto lua_script = store->get_lua_script_manager();

  return lua_script->put(dpp, y, script_oid(ctx, tenant), script);
}

int delete_script(const DoutPrefixProvider *dpp, rgw::sal::Store* store, const std::string& tenant, optional_yield y, context ctx)
{
  auto lua_script = store->get_lua_script_manager();

  return lua_script->del(dpp, y, script_oid(ctx, tenant));
}

#ifdef WITH_RADOSGW_LUA_PACKAGES

const std::string PACKAGE_LIST_OBJECT_NAME = "lua_package_allowlist";

namespace bp = boost::process;

int add_package(const DoutPrefixProvider *dpp, rgw::sal::RadosStore* store, optional_yield y, const std::string& package_name, bool allow_compilation) {
  // verify that luarocks can load this package
  const auto p = bp::search_path("luarocks");
  if (p.empty()) {
    return -ECHILD;
  }
  bp::ipstream is;
  const auto cmd = p.string() + " search --porcelain" + (allow_compilation ? " " : " --binary ") + package_name;
  bp::child c(cmd,
      bp::std_in.close(),
      bp::std_err > bp::null,
      bp::std_out > is);

  std::string line;
  bool package_found = false;
  while (c.running() && std::getline(is, line) && !line.empty()) {
    package_found = true;
  }
  c.wait();
  auto ret = c.exit_code();
  if (ret) {
    return -ret;
  }

  if (!package_found) {
    return -EINVAL;
  }
  
  //replace previous versions of the package
  const std::string package_name_no_version = package_name.substr(0, package_name.find(" "));
  ret = remove_package(dpp, store, y, package_name_no_version);
  if (ret < 0) {
    return ret;
  }

  // add package to list
  const bufferlist empty_bl;
  std::map<std::string, bufferlist> new_package{{package_name, empty_bl}};
  librados::ObjectWriteOperation op;
  op.omap_set(new_package);
  ret = rgw_rados_operate(dpp, *(store->getRados()->get_lc_pool_ctx()),
      PACKAGE_LIST_OBJECT_NAME, &op, y);

  if (ret < 0) {
    return ret;
  } 
  return 0;
}

int remove_package(const DoutPrefixProvider *dpp, rgw::sal::RadosStore* store, optional_yield y, const std::string& package_name) {
  librados::ObjectWriteOperation op;
  size_t pos = package_name.find(" ");
  if (pos != package_name.npos) {
    // remove specfic version of the the package
    op.omap_rm_keys(std::set<std::string>({package_name}));
    auto ret = rgw_rados_operate(dpp, *(store->getRados()->get_lc_pool_ctx()),
        PACKAGE_LIST_OBJECT_NAME, &op, y);
    if (ret < 0) {
        return ret;
    }
    return 0;
  }
  // otherwise, remove any existing versions of the package
  packages_t packages;
  auto ret = list_packages(dpp, store, y, packages);
  if (ret < 0 && ret != -ENOENT) {
    return ret;
  }
  for(const auto& package : packages) {
    const std::string package_no_version = package.substr(0, package.find(" "));
    if (package_no_version.compare(package_name) == 0) {
        op.omap_rm_keys(std::set<std::string>({package}));
        ret = rgw_rados_operate(dpp, *(store->getRados()->get_lc_pool_ctx()),
            PACKAGE_LIST_OBJECT_NAME, &op, y);
        if (ret < 0) {
            return ret;
        }
    }
  }
  return 0;
}

int list_packages(const DoutPrefixProvider *dpp, rgw::sal::RadosStore* store, optional_yield y, packages_t& packages) {
  constexpr auto max_chunk = 1024U;
  std::string start_after;
  bool more = true;
  int rval;
  while (more) {
    librados::ObjectReadOperation op;
    packages_t packages_chunk;
    op.omap_get_keys2(start_after, max_chunk, &packages_chunk, &more, &rval);
    const auto ret = rgw_rados_operate(dpp, *(store->getRados()->get_lc_pool_ctx()),
      PACKAGE_LIST_OBJECT_NAME, &op, nullptr, y);
  
    if (ret < 0) {
      return ret;
    }

    packages.merge(packages_chunk);
  }
 
  return 0;
}

int install_packages(const DoutPrefixProvider *dpp, rgw::sal::RadosStore* store, optional_yield y, packages_t& failed_packages, std::string& output) {
  // luarocks directory cleanup
  std::error_code ec;
  const auto& luarocks_path = store->get_luarocks_path();
  if (std::filesystem::remove_all(luarocks_path, ec)
      == static_cast<std::uintmax_t>(-1) &&
      ec != std::errc::no_such_file_or_directory) {
    output.append("failed to clear luarock directory: ");
    output.append(ec.message());
    output.append("\n");
    return ec.value();
  }

  packages_t packages;
  auto ret = list_packages(dpp, store, y, packages);
  if (ret == -ENOENT) {
    // allowlist is empty 
    return 0;
  }
  if (ret < 0) {
    return ret;
  }
  // verify that luarocks exists
  const auto p = bp::search_path("luarocks");
  if (p.empty()) {
    return -ECHILD;
  }

  // the lua rocks install dir will be created by luarocks the first time it is called
  for (const auto& package : packages) {
    bp::ipstream is;
    const auto cmd = p.string() + " install --lua-version " + CEPH_LUA_VERSION + " --tree " + luarocks_path + " --deps-mode one " + package;
    bp::child c(cmd, bp::std_in.close(), (bp::std_err & bp::std_out) > is);

    // once package reload is supported, code should yield when reading output
    std::string line = std::string("CMD: ") + cmd;

    do {
      if (!line.empty()) {
        output.append(line);
        output.append("\n");
      }
    } while (c.running() && std::getline(is, line));

    c.wait();
    if (c.exit_code()) {
      failed_packages.insert(package);
    }
  }

  return 0;
}

#endif

}

